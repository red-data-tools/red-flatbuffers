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

require "test-unit"

require "flatbuffers/generator"

module Helper
  module Path
    class << self
      attr_accessor :flatbuffers_repository
      attr_accessor :tmp_dir
      attr_accessor :reflection_bfbs
    end
  end

  module Fixture
    class << self
      def prepare
        reflection_dir = Path.tmp_dir + "reflection"
        FileUtils.mkdir_p(reflection_dir)
        reflection_fbs =
          Path.flatbuffers_repository + "reflection" + "reflection.fbs"
        Path.reflection_bfbs = reflection_dir + "reflection.bfbs"
        run_flatc("-o", reflection_dir.to_s,
                  "--binary",
                  "--schema",
                  "--bfbs-builtins",
                  "--bfbs-comments",
                  reflection_fbs.to_s)
        Path.reflection_bfbs.open("rb") do |bfbs|
          input = IO::Buffer.map(bfbs, nil, 0, IO::Buffer::READONLY)
          generator = FlatBuffers::Generator.new(input)
          generator.output_dir = reflection_dir
          generator.generate
        end
        $LOAD_PATH.unshift(reflection_dir.to_s)

        monster_dir = Path.tmp_dir + "monster"
        FileUtils.mkdir_p(monster_dir)
        tests_dir = Path.flatbuffers_repository + "tests"
        monster_test_bfbs = tests_dir + "monster_test.bfbs"
        monster_test_bfbs.open("rb") do |bfbs|
          input = IO::Buffer.map(bfbs, nil, 0, IO::Buffer::READONLY)
          generator = FlatBuffers::Generator.new(input)
          generator.output_dir = monster_dir
          generator.generate
        end
        $LOAD_PATH.unshift(monster_dir.to_s)
      end

      def run_flatc(*args)
        unless system("flatc", *args)
          raise "Failed to run flatc: flatc #{args.join(" ")}"
        end
      end
    end
  end
end
