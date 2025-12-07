# Copyright 2025 Sutou Kouhei <kou@clear-code.com>
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

class TestGenerator < Test::Unit::TestCase
  class TestNameConvertable < self
    class NameConverter
      name_convertable = FlatBuffers::Generator::NameConvertable
      include name_convertable

      name_convertable.private_instance_methods(false).each do |name|
        public name
      end
    end

    def setup
      @converter = NameConverter.new
    end

    sub_test_case("#to_class_name") do
      def test_last_underscore
        assert_equal("Struct",
                     @converter.to_class_name("Struct_"))
      end
    end
  end
end
