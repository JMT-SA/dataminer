ProgramSchema = Dry::Validation.Schema do
  required(:program_name).filled(:str?)
  optional(:webapps).filled(:array?)
end
