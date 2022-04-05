defmodule Tile38Test do
  use ExUnit.Case
  doctest Tile38
  import Tile38

  setup_all do
    {:ok, _} = Redix.start_link("redis://localhost:9851/", name: :tile38)

    :ok
  end

  setup do
    clear_database()

    :ok
  end

  describe "#f38" do
    test "request an object with fields from Tile38" do
      id = "123"

      t38("set mycollection #{id} field firstfield 10 field secondfield 20 point 10 -10 123")

      object_with_fields = f38("get mycollection #{id} withfields")

      assert(object_with_fields.fields.firstfield == "10")
      assert(object_with_fields.fields.secondfield == "20")
      assert(object_with_fields.coordinates.lat == 10)
      assert(object_with_fields.coordinates.lng == -10)
      assert(object_with_fields.coordinates.timestamp == 123)
      assert(object_with_fields.coordinates.type == "Point")
    end

    test "flip field order" do
      id = "123"
      t38("set participants #{id} field secondfield 20 field firstfield 10 point 10 -10")

      object_with_fields = f38("get participants #{id} withfields")

      assert(object_with_fields.fields.firstfield == "10")
      assert(object_with_fields.fields.secondfield == "20")
      assert(object_with_fields.coordinates.lat == 10)
      assert(object_with_fields.coordinates.lng == -10)
      assert(object_with_fields.coordinates.timestamp == nil)
      assert(object_with_fields.coordinates.type == "Point")
    end

    test "no fields, no timestamp" do
      id = "123"
      t38("set participants #{id} point 10 -10")

      result = f38("get participants #{id} withfields")

      assert(result.coordinates.lat == 10)
      assert(result.coordinates.lng == -10)
      assert(result.coordinates.timestamp == nil)
    end

    test "no fields but timestamp" do
      id = "123"
      t38("set participants #{id} point 10 -10 123")

      result = f38("get participants #{id} withfields")

      assert(result.coordinates.lat == 10)
      assert(result.coordinates.lng == -10)
      assert(result.coordinates.timestamp == 123)
    end

    test "no results" do
      id = "123"

      result = f38("get participants #{id} withfields")

      assert(result == nil)
    end
  end

  describe "#n38" do
    test "no points nearby" do
      response = n38("nearby participants point 0 0")

      assert(response == [])
    end

    test "single point nearby" do
      id = "123"
      t38("set participants #{id} field my_field 123 point 10 -10 99")

      [response] = n38("nearby participants point 0 0")

      assert(response.id == "123")
      assert(response.coordinates.lat == 10)
      assert(response.coordinates.lng == -10)
      assert(response.coordinates.timestamp == 99)
    end

    test "multiple points nearby" do
      id = "0123"
      other_id = "0321"
      t38("set participants #{id} field my_field 123 field my_other_field 321 point 0 0")
      t38("set participants #{other_id} point 10 -10 10000")

      response = n38("nearby participants point 0 0")

      [first, second] = response

      assert(first.id == "0321")
      assert(first.coordinates.lat == 10)
      assert(first.coordinates.lng == -10)
      assert(first.coordinates.timestamp == 10000)
      assert(second.id == "0123")
      assert(second.coordinates.lat == 0)
      assert(second.coordinates.lng == 0)
      assert(second.coordinates.timestamp == nil)
      assert(second.fields.my_field == "123")
      assert(second.fields.my_other_field == "321")
    end
  end
end
