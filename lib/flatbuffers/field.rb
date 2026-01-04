# Copyright 2025-2026 Sutou Kouhei <kou@clear-code.com>
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

require_relative "view"

module FlatBuffers
  class Field
    attr_reader :name
    attr_reader :index
    attr_reader :offset
    attr_reader :base_type
    attr_reader :padding
    def initialize(name, index, offset, base_type, padding)
      @name = name
      @index = index
      @offset = offset
      @base_type = base_type
      @padding = padding
    end
  end
end
