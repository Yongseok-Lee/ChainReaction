-- Prototype 0.95 object catalog structural validator.

local M = {}

local CATALOG_METADATA_KEYS = {
  availableOrder = true,
}

local ALLOWED_OBJECT_FIELDS = {
  attributes = true,
  orderStatus = true,
}

local ALLOWED_ATTRIBUTE_FIELDS = {
  key = true,
  params = true,
}

local EXPECTED_SINGLE_COUNT = 7
local EXPECTED_DUAL_COUNT = 21
local EXPECTED_EXECUTABLE_OBJECT_COUNT = 28
local EXPECTED_SINGLE_ATTRIBUTE_KEYS = {
  "ignite",
  "amplify",
  "store",
  "release",
  "charge",
  "echo",
  "explode",
}

local function add_error(errors, error_data)
  errors[#errors + 1] = error_data
end

local function canonical_dual_pair_key(a, b)
  if a <= b then
    return a .. "|" .. b
  end
  return b .. "|" .. a
end

local function sorted_field_keys(row)
  local keys = {}
  for field_name, _ in pairs(row) do
    keys[#keys + 1] = field_name
  end

  table.sort(keys, function(a, b)
    local type_a = type(a)
    local type_b = type(b)
    if type_a ~= type_b then
      return type_a < type_b
    end
    return tostring(a) < tostring(b)
  end)

  return keys
end

local function validate_dense_array_shape(value)
  if type(value) ~= "table" then
    return false, 0
  end

  local count = 0
  local max_index = 0
  for key, _ in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
      return false, 0
    end
    count = count + 1
    if key > max_index then
      max_index = key
    end
  end

  if max_index ~= count then
    return false, 0
  end

  return true, count
end

local function collect_sorted_object_keys(catalog)
  local keys = {}
  for root_key, _ in pairs(catalog) do
    if not CATALOG_METADATA_KEYS[root_key] then
      keys[#keys + 1] = root_key
    end
  end

  table.sort(keys, function(a, b)
    local type_a = type(a)
    local type_b = type(b)
    if type_a ~= type_b then
      return type_a < type_b
    end
    return tostring(a) < tostring(b)
  end)

  return keys
end

local function collect_sorted_string_keys(set_table)
  local keys = {}
  for key, value in pairs(set_table) do
    if value == true and type(key) == "string" then
      keys[#keys + 1] = key
    end
  end
  table.sort(keys)
  return keys
end

local function build_expected_dual_pair_set()
  local expected = {}
  for i = 1, #EXPECTED_SINGLE_ATTRIBUTE_KEYS do
    for j = i + 1, #EXPECTED_SINGLE_ATTRIBUTE_KEYS do
      local pair_key =
        canonical_dual_pair_key(EXPECTED_SINGLE_ATTRIBUTE_KEYS[i], EXPECTED_SINGLE_ATTRIBUTE_KEYS[j])
      expected[pair_key] = true
    end
  end
  return expected
end

local function validate_available_order(catalog, errors)
  local available_order = catalog.availableOrder
  if type(available_order) ~= "table" then
    add_error(errors, {
      code = "ERR_INVALID_AVAILABLE_ORDER",
      note = "availableOrder must be a table.",
      field = "availableOrder",
    })
    return
  end

  local is_dense_array, available_count = validate_dense_array_shape(available_order)
  if not is_dense_array then
    add_error(errors, {
      code = "ERR_INVALID_AVAILABLE_ORDER",
      note = "availableOrder must be a dense ordered array with indices 1..N.",
      field = "availableOrder",
    })
    return
  end

  local seen = {}
  for index = 1, available_count do
    local object_key = available_order[index]
    if type(object_key) ~= "string" or object_key == "" then
      add_error(errors, {
        code = "ERR_INVALID_AVAILABLE_ORDER",
        note = "availableOrder entries must be non-empty strings.",
        field = "availableOrder",
        availableOrderIndex = index,
      })
    else
      if seen[object_key] then
        add_error(errors, {
          code = "ERR_AVAILABLE_ORDER_DUPLICATE_KEY",
          note = "Duplicate object key in availableOrder.",
          field = "availableOrder",
          objectKey = object_key,
          availableOrderIndex = index,
        })
      end
      seen[object_key] = true

      if catalog[object_key] == nil or CATALOG_METADATA_KEYS[object_key] then
        add_error(errors, {
          code = "ERR_AVAILABLE_ORDER_UNKNOWN_KEY",
          note = "availableOrder key does not match an object definition.",
          field = "availableOrder",
          objectKey = object_key,
          availableOrderIndex = index,
        })
      end
    end
  end
end

local function validate_object_fields(object_key, object_def, errors)
  local field_keys = sorted_field_keys(object_def)
  for _, field_name in ipairs(field_keys) do
    if field_name == "id" or field_name == "key" then
      add_error(errors, {
        code = "ERR_INTERNAL_ID_FORBIDDEN",
        note = "Object identity must use the catalog map key, not an internal id/key field.",
        objectKey = object_key,
        field = field_name,
      })
    elseif not ALLOWED_OBJECT_FIELDS[field_name] then
      add_error(errors, {
        code = "ERR_UNKNOWN_OBJECT_FIELD",
        note = "Unsupported object field in catalog row.",
        objectKey = object_key,
        field = field_name,
      })
    end
  end
end

local function validate_order_status(object_key, object_def, errors)
  local order_status = object_def.orderStatus
  if order_status ~= nil and order_status ~= "provisional" then
    add_error(errors, {
      code = "ERR_INVALID_ORDER_STATUS",
      note = "orderStatus must be omitted or set to 'provisional'.",
      objectKey = object_key,
      field = "orderStatus",
    })
  end
end

local function validate_attributes(object_key, object_def, supported_attributes, errors)
  local attributes = object_def.attributes
  if type(attributes) ~= "table" then
    add_error(errors, {
      code = "ERR_INVALID_OBJECT_ATTRIBUTES",
      note = "Object attributes must be an ordered non-empty table.",
      objectKey = object_key,
      field = "attributes",
    })
    return nil
  end

  local is_dense_array, attribute_count = validate_dense_array_shape(attributes)
  if not is_dense_array then
    add_error(errors, {
      code = "ERR_INVALID_OBJECT_ATTRIBUTES",
      note = "Object attributes must be a dense ordered array with indices 1..N.",
      objectKey = object_key,
      field = "attributes",
    })
    return nil, 0
  end

  if attribute_count < 1 or attribute_count > 2 then
    add_error(errors, {
      code = "ERR_INVALID_OBJECT_ATTRIBUTES",
      note = "Object attributes count must be 1 or 2.",
      objectKey = object_key,
      field = "attributes",
    })
  end

  local seen = {}
  for attribute_index = 1, attribute_count do
    local entry = attributes[attribute_index]
    if type(entry) ~= "table" then
      add_error(errors, {
        code = "ERR_INVALID_ATTRIBUTE_ENTRY",
        note = "Attribute entry must be a table.",
        objectKey = object_key,
        attributeIndex = attribute_index,
      })
    else
      local field_keys = sorted_field_keys(entry)
      for _, field_name in ipairs(field_keys) do
        if not ALLOWED_ATTRIBUTE_FIELDS[field_name] then
          add_error(errors, {
            code = "ERR_UNKNOWN_ATTRIBUTE_FIELD",
            note = "Unsupported attribute-entry field.",
            objectKey = object_key,
            attributeIndex = attribute_index,
            field = field_name,
          })
        end
      end

      local attribute_key = entry.key
      if type(attribute_key) ~= "string" or attribute_key == "" then
        add_error(errors, {
          code = "ERR_INVALID_ATTRIBUTE_ENTRY",
          note = "Attribute key must be a non-empty string.",
          objectKey = object_key,
          attributeIndex = attribute_index,
          field = "key",
        })
      else
        if seen[attribute_key] then
          add_error(errors, {
            code = "ERR_DUPLICATE_ATTRIBUTE",
            note = "Duplicate attribute keys are invalid for one object.",
            objectKey = object_key,
            attributeIndex = attribute_index,
            field = "key",
          })
        end
        seen[attribute_key] = true

        if supported_attributes[attribute_key] ~= true then
          add_error(errors, {
            code = "ERR_UNSUPPORTED_ATTRIBUTE",
            note = "Attribute key is not in supported attribute set.",
            objectKey = object_key,
            attributeIndex = attribute_index,
            field = "key",
          })
        end
      end

      if type(entry.params) ~= "table" then
        add_error(errors, {
          code = "ERR_INVALID_ATTRIBUTE_ENTRY",
          note = "Attribute params must be a table.",
          objectKey = object_key,
          attributeIndex = attribute_index,
          field = "params",
        })
      end
    end
  end

  return attributes, attribute_count
end

local function validate_catalog_completeness(object_defs, object_keys, errors)
  local single_count = 0
  local dual_count = 0
  local executable_count = 0
  local expected_single_set = {}
  local observed_single_set = {}
  local expected_dual_pair_set = build_expected_dual_pair_set()
  local observed_dual_pair_set = {}

  for _, key in ipairs(EXPECTED_SINGLE_ATTRIBUTE_KEYS) do
    expected_single_set[key] = true
  end

  for _, object_key in ipairs(object_keys) do
    local object_def = object_defs[object_key]
    if type(object_def) == "table" and type(object_def.attributes) == "table" then
      local is_dense_array, attribute_count = validate_dense_array_shape(object_def.attributes)
      if is_dense_array then
        if attribute_count == 1 then
          single_count = single_count + 1
          executable_count = executable_count + 1
          local entry = object_def.attributes[1]
          local attribute_key = type(entry) == "table" and entry.key or nil
          if type(attribute_key) == "string" and attribute_key ~= "" then
            observed_single_set[attribute_key] = true
          end
        elseif attribute_count == 2 then
          dual_count = dual_count + 1
          executable_count = executable_count + 1
          local first = object_def.attributes[1]
          local second = object_def.attributes[2]
          local first_key = type(first) == "table" and first.key or nil
          local second_key = type(second) == "table" and second.key or nil
          if type(first_key) == "string" and first_key ~= "" and type(second_key) == "string" and second_key ~= "" then
            local pair_key = canonical_dual_pair_key(first_key, second_key)
            observed_dual_pair_set[pair_key] = true
          end
        end
      end
    end
  end

  if single_count ~= EXPECTED_SINGLE_COUNT then
    add_error(errors, {
      code = "ERR_CATALOG_SINGLE_COUNT",
      note = "Catalog must contain exactly 7 single-attribute objects.",
      field = "catalogSingleCount",
    })
  end

  if dual_count ~= EXPECTED_DUAL_COUNT then
    add_error(errors, {
      code = "ERR_CATALOG_DUAL_COUNT",
      note = "Catalog must contain exactly 21 dual-attribute objects.",
      field = "catalogDualCount",
    })
  end

  if executable_count ~= EXPECTED_EXECUTABLE_OBJECT_COUNT then
    add_error(errors, {
      code = "ERR_CATALOG_TOTAL_COUNT",
      note = "Catalog must contain exactly 28 executable objects.",
      field = "catalogTotalCount",
    })
  end

  for _, expected_single_key in ipairs(EXPECTED_SINGLE_ATTRIBUTE_KEYS) do
    if observed_single_set[expected_single_key] ~= true then
      add_error(errors, {
        code = "ERR_CATALOG_SINGLE_COVERAGE_MISSING",
        note = "Catalog is missing expected single-attribute coverage.",
        field = "catalogSingleCoverage",
        attribute = expected_single_key,
      })
    end
  end

  local unexpected_single_keys = {}
  for single_key, _ in pairs(observed_single_set) do
    if expected_single_set[single_key] ~= true then
      unexpected_single_keys[#unexpected_single_keys + 1] = single_key
    end
  end
  table.sort(unexpected_single_keys)
  for _, unexpected_single_key in ipairs(unexpected_single_keys) do
    add_error(errors, {
      code = "ERR_CATALOG_SINGLE_COVERAGE_UNEXPECTED",
      note = "Catalog contains unexpected single-attribute coverage.",
      field = "catalogSingleCoverage",
      attribute = unexpected_single_key,
    })
  end

  local expected_dual_pair_keys = collect_sorted_string_keys(expected_dual_pair_set)
  for _, expected_pair_key in ipairs(expected_dual_pair_keys) do
    if observed_dual_pair_set[expected_pair_key] ~= true then
      add_error(errors, {
        code = "ERR_CATALOG_DUAL_PAIR_MISSING",
        note = "Catalog is missing expected unordered dual-pair coverage.",
        field = "catalogDualCoverage",
        dualPairKey = expected_pair_key,
      })
    end
  end

  local unexpected_dual_pair_keys = {}
  for pair_key, _ in pairs(observed_dual_pair_set) do
    if expected_dual_pair_set[pair_key] ~= true then
      unexpected_dual_pair_keys[#unexpected_dual_pair_keys + 1] = pair_key
    end
  end
  table.sort(unexpected_dual_pair_keys)
  for _, unexpected_pair_key in ipairs(unexpected_dual_pair_keys) do
    add_error(errors, {
      code = "ERR_CATALOG_DUAL_PAIR_UNEXPECTED",
      note = "Catalog contains unexpected unordered dual-pair coverage.",
      field = "catalogDualCoverage",
      dualPairKey = unexpected_pair_key,
    })
  end
end

function M.validateCatalog(object_defs, supported_attributes, options)
  local errors = {}
  local enforce_completeness = type(options) == "table" and options.enforceCompleteness == true

  if type(object_defs) ~= "table" then
    return {
      ok = false,
      errors = {
        {
          code = "ERR_INVALID_OBJECTS",
          note = "objectDefs must be a table.",
        },
      },
    }
  end

  if type(supported_attributes) ~= "table" then
    return {
      ok = false,
      errors = {
        {
          code = "ERR_INVALID_OBJECTS",
          note = "supportedAttributes must be a table of attribute keys.",
        },
      },
    }
  end

  validate_available_order(object_defs, errors)

  local dual_pairs_seen = {}
  local object_keys = collect_sorted_object_keys(object_defs)
  for _, object_key in ipairs(object_keys) do
    local object_def = object_defs[object_key]
    if type(object_key) ~= "string" or object_key == "" then
      add_error(errors, {
        code = "ERR_INVALID_OBJECT_DEF",
        note = "Object map keys must be non-empty strings.",
        field = "objectKey",
      })
    elseif type(object_def) ~= "table" then
      add_error(errors, {
        code = "ERR_INVALID_OBJECT_DEF",
        note = "Object definition must be a table.",
        objectKey = object_key,
      })
    else
      validate_object_fields(object_key, object_def, errors)
      validate_order_status(object_key, object_def, errors)
      local attributes, attribute_count =
        validate_attributes(object_key, object_def, supported_attributes, errors)

      if type(attributes) == "table" and attribute_count == 2 then
        local first = attributes[1]
        local second = attributes[2]
        local first_key = type(first) == "table" and first.key or nil
        local second_key = type(second) == "table" and second.key or nil
        if type(first_key) == "string" and first_key ~= "" and type(second_key) == "string" and second_key ~= "" then
          local pair_key = canonical_dual_pair_key(first_key, second_key)
          local previous_object = dual_pairs_seen[pair_key]
          if previous_object ~= nil then
            add_error(errors, {
              code = "ERR_DUPLICATE_DUAL_PAIR",
              note = "Duplicate unordered dual attribute pair in catalog.",
              objectKey = object_key,
              dualPairKey = pair_key,
            })
          else
            dual_pairs_seen[pair_key] = object_key
          end
        end
      end
    end
  end

  if enforce_completeness then
    validate_catalog_completeness(object_defs, object_keys, errors)
  end

  return {
    ok = #errors == 0,
    errors = errors,
  }
end

return M
