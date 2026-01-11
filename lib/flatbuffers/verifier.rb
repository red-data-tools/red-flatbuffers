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

require_relative "append_as_bytes"

module FlatBuffers
  class Verifier
    def initialize(target)
      @target = target
    end

    def verify
      view = @target.instance_variable_get(:@view)
      @target.class::FIELDS.each_value do |field|
        offset = view.offset + view.unpack_virtual_offset(field.offset)
        verify_alignment(field, offset)
        case field.base_type
        when String
          sub_target = @target.public_send(field.name)
          next if sub_target.nil?
          next if sub_target.is_a?(Struct)
          Verifier.new(sub_target).verify
        when Array
          next unless field.base_type[0].is_a?(String)
          @target.public_send(field.name)&.each do |value|
            next if value.is_a?(Struct)
            Verifier.new(value).verify
          end
        end
      end
    end

    private
    def verify_alignment(field, offset)
      unless (offset % field.alignment_size).zero?
        message = "#{@target.class.name}'s #{field.name} " +
                  "(#{field.base_type}) value isn't aligned: #{offset}: " +
                  "#{field.alignment_size}"
        raise VerificationError.new(message)
      end
    end
  end
end
