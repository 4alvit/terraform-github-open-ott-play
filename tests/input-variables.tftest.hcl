variables {
  github_token = "local-test-no-authentication"
}

run "unused_billing_email_can_be_omitted" {
  command = plan
  assert {
    condition     = nonsensitive(var.billing_email) == null
    error_message = "The currently unused billing input must not be required."
  }
}

run "explicit_billing_email_is_preserved" {
  command = plan
  variables {
    billing_email = "local-fixture@example.invalid"
  }
  assert {
    condition     = nonsensitive(var.billing_email) == "local-fixture@example.invalid"
    error_message = "An explicitly supplied billing input must be preserved."
  }
}
