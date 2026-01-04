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

require "my_game/example/monster"

class TestMonsterSerializer < Test::Unit::TestCase
  class TestMonster < self
    def roundtrip(monster)
      data = MyGame::Example::Monster.serialize(monster)
      MyGame::Example::Monster.new(data)
    end

    def test_pos
      monster = MyGame::Example::Monster::Data.new
      vec3 = MyGame::Example::Vec3::Data.new
      vec3.x = 1.0
      monster.pos = vec3
      monster = roundtrip(monster)
      assert_equal(1.0, monster.pos.x)
    end

    def test_hp
      monster = MyGame::Example::Monster::Data.new
      monster.hp = -(2 ** 15)
      monster = roundtrip(monster)
      assert_equal(-(2 ** 15), monster.hp)
    end

    def test_test
      monster = MyGame::Example::Monster::Data.new
      other_monster = MyGame::Example::Monster::Data.new
      other_monster.name = "OtherMonster"
      monster.test = other_monster
      monster = roundtrip(monster)
      assert_equal("OtherMonster", monster.test.name)
    end

    def test_test4
      monster = MyGame::Example::Monster::Data.new
      test =  MyGame::Example::Test::Data.new
      test.a = -(2 ** 15)
      test.b = -(2 ** 7)
      monster.test4 = [test]
      monster = roundtrip(monster)
      assert_equal([[-(2 ** 15), -(2 ** 7)]],
                   monster.test4.collect {|t| [t.a, t.b]})
    end

    def test_testf
      monster = MyGame::Example::Monster::Data.new
      monster.testf = 3.14159
      monster = roundtrip(monster)
      assert_in_delta(3.14159, monster.testf)
    end
  end

  class TestVec3 < self
    def roundtrip(vec3)
      monster = MyGame::Example::Monster::Data.new
      monster.pos = vec3
      data = MyGame::Example::Monster.serialize(monster)
      MyGame::Example::Monster.new(data).pos
    end

    def test_test1
      vec3 = MyGame::Example::Vec3::Data.new
      vec3.test1 = 1.0
      vec3 = roundtrip(vec3)
      assert_equal(1.0, vec3.test1)
    end

  end
end
