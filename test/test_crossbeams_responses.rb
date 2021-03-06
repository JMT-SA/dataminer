require File.join(File.expand_path('./', __dir__), 'test_helper')

class TestCrossbeamsResponses < Minitest::Test
  def setup
    @test_obj = Object.new
    @test_obj.extend Crossbeams::Responses
  end

  def test_success_response_without_instance
    res = @test_obj.success_response('OK')

    assert res.success
    assert_equal 'OK', res.message
    assert_empty res.errors
    assert_nil res.instance
  end

  def test_success_response_with_instance
    res = @test_obj.success_response('OK', { thing: 'A' })

    assert res.success
    assert_equal 'OK', res.message
    assert_empty res.errors
    assert_equal 'A', res.instance[:thing]
  end

  def test_failed_response_without_instance
    res = @test_obj.failed_response('OHNO')

    refute res.success
    assert_equal 'OHNO', res.message
    assert_empty res.errors
    assert_nil res.instance
  end

  def test_failed_response_with_instance
    res = @test_obj.failed_response('OHNO', { thing: 'A' })

    refute res.success
    assert_equal 'OHNO', res.message
    assert_empty res.errors
    assert_equal 'A', res.instance[:thing]
  end

  def test_validation_failed
    res = @test_obj.validation_failed_response(OpenStruct.new(messages: 'OHNO'))

    refute res.success
    assert_equal 'Validation error', res.message
    assert_equal 'OHNO', res.errors
    assert_equal({}, res.instance)
  end

  def test_validation_failed_with_struct
    res = @test_obj.validation_failed_response(OpenStruct.new(messages: 'OHNO', thing: 'A'))

    assert_equal 'A', res.instance[:thing]
  end

  def test_validation_failed_with_dry
    schema = Dry::Validation.Form do
      configure { config.type_specs = true }

      required(:in, Types::StrippedString).filled(:str?)
    end
    validation = schema.call(dummy: nil)
    res = @test_obj.validation_failed_response(validation)

    refute res.success
    assert_equal 'Validation error', res.message
    assert_equal({:in=>["is missing"]}, res.errors)
    assert_equal({}, res.instance)
  end

  def test_validation_failed_with_dry_and_instance
    schema = Dry::Validation.Form do
      configure { config.type_specs = true }

      required(:in, Types::StrippedString).filled(:str?)
      required(:other, Types::StrippedString).filled(:str?)
    end
    validation = schema.call(other: 'abc')
    res = @test_obj.validation_failed_response(validation)

    assert_equal({:in=>["is missing"]}, res.errors)
    assert_equal({ other: 'abc' }, res.instance)
  end
end
