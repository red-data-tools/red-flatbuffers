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

module FlatBuffers
  module DataDefinable
    def define_data_class
      if self::FIELDS.empty?
        klass = Class.new
      else
        klass = ::Struct.new(*self::FIELDS.keys) do
          members.each do |member|
            next unless member.end_with?("?")
            alias_method :"#{member.to_s.delete_suffix("?")}=", :"#{member}="
          end
        end
      end
      table_class = self
      klass.singleton_class.define_method(:table_class) do
        table_class
      end
      klass
    end
  end
end
