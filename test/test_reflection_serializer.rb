# Copyright 2026 Sutou Kouhei <kou@clear-code.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "reflection/schema"

class TestReflectionSerializer < Test::Unit::TestCase
  class TestSchema < self
    def roundtrip(schema)
      data = Reflection::Schema.serialize(schema)
      Reflection::Schema.new(data)
    end

    def test_objects
      schema = Reflection::Schema::Data.new
      objects = []
      object1 = Reflection::Object::Data.new
      object1.name = "Object1"
      objects << object1
      object2 = Reflection::Object::Data.new
      object2.name = "Object2"
      objects << object2
      schema.objects = objects
      schema = roundtrip(schema)
      assert_equal(["Object1", "Object2"],
                   schema.objects.collect(&:name))
    end

    def test_file_ident
      schema = Reflection::Schema::Data.new
      schema.file_ident = "BFBS"
      schema = roundtrip(schema)
      assert_equal("BFBS", schema.file_ident)
    end

    def test_root_table
      schema = Reflection::Schema::Data.new
      root_table = Reflection::Object::Data.new
      root_table.name = "RootTable"
      schema.root_table = root_table
      schema = roundtrip(schema)
      assert_equal("RootTable", schema.root_table.name)
    end

    def test_services_nil
      schema = Reflection::Schema::Data.new
      schema.services = nil
      schema = roundtrip(schema)
      assert_nil(schema.services)
    end

    def test_advanced_features
      schema = Reflection::Schema::Data.new
      schema.advanced_features =
        Reflection::AdvancedFeatures::OPTIONAL_SCALARS.value
      schema = roundtrip(schema)
      assert_equal(Reflection::AdvancedFeatures::OPTIONAL_SCALARS,
                   schema.advanced_features)
    end
  end

  class TestObject < self
    def roundtrip(object)
      schema = Reflection::Schema::Data.new
      schema.root_table = object
      data = Reflection::Schema.serialize(schema)
      schema = Reflection::Schema.new(data)
      schema.root_table
    end

    def test_struct
      object = Reflection::Object::Data.new
      object.struct = true
      object = roundtrip(object)
      assert do
        object.struct?
      end
    end

    def test_minalign
      object = Reflection::Object::Data.new
      object.minalign = -1
      object = roundtrip(object)
      assert_equal(-1, object.minalign)
    end

    def test_documentation
      object = Reflection::Object::Data.new
      object.documentation = ["line1", "line2"]
      object = roundtrip(object)
      assert_equal(["line1", "line2"], object.documentation)
    end
  end

  class TestField < self
    def roundtrip(field)
      schema = Reflection::Schema::Data.new
      object = Reflection::Object::Data.new
      object.fields = [field]
      schema.root_table = object
      data = Reflection::Schema.serialize(schema)
      schema = Reflection::Schema.new(data)
      schema.root_table.fields[0]
    end

    def test_id
      field = Reflection::Field::Data.new
      field.id = 2 ** 16 - 1
      field = roundtrip(field)
      assert_equal(2 ** 16 - 1, field.id)
    end

    def test_default_integer
      field = Reflection::Field::Data.new
      field.default_integer = -(2 ** 63)
      field = roundtrip(field)
      assert_equal(-(2 ** 63), field.default_integer)
    end

    def test_default_double
      field = Reflection::Field::Data.new
      field.default_real = -2.9
      field = roundtrip(field)
      assert_equal(-2.9, field.default_real)
    end

    def test_padding
      field = Reflection::Field::Data.new
      field.padding = 2 ** 16 - 1
      field = roundtrip(field)
      assert_equal(2 ** 16 - 1, field.padding)
    end
  end

  class TestType < self
    def roundtrip(type)
      schema = Reflection::Schema::Data.new
      object = Reflection::Object::Data.new
      field = Reflection::Field::Data.new
      field.type = type
      object.fields = [field]
      schema.root_table = object
      data = Reflection::Schema.serialize(schema)
      schema = Reflection::Schema.new(data)
      schema.root_table.fields[0].type
    end

    def test_fixed_length
      type = Reflection::Type::Data.new
      type.fixed_length = 2 ** 16 - 1
      type = roundtrip(type)
      assert_equal(2 ** 16 - 1, type.fixed_length)
    end

    def test_base_size
      type = Reflection::Type::Data.new
      type.base_size = 2 ** 32 - 1
      type = roundtrip(type)
      assert_equal(2 ** 32 - 1, type.base_size)
    end

    def test_base_type
      type = Reflection::Type::Data.new
      type.base_type = Reflection::BaseType::UTYPE.value
      type = roundtrip(type)
      assert_equal(Reflection::BaseType::UTYPE, type.base_type)
    end
  end

  class TestEnum < self
    def roundtrip(enum)
      schema = Reflection::Schema::Data.new
      schema.enums = [enum]
      data = Reflection::Schema.serialize(schema)
      schema = Reflection::Schema.new(data)
      schema.enums.first
    end

    def test_values
      enum = Reflection::Enum::Data.new
      enum_val1 = Reflection::EnumVal::Data.new
      enum_val1.name = "EnumValue1"
      enum_val2 = Reflection::EnumVal::Data.new
      enum_val2.name = "EnumValue2"
      enum.values = [enum_val1, enum_val2]
      enum = roundtrip(enum)
      assert_equal(["EnumValue1", "EnumValue2"],
                   enum.values.collect(&:name))
    end
  end
end
