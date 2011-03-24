Feature: Testing feature system

  Scenario: Scenario test
    Given I am on path "/index.php"
    Then I should see "Welcome to the site:"

  @javascript
  Scenario: Signing in
    Given I am on path "/login.php"
    When I fill in "user@yoursitehere.com" for "Email"
    And I fill in "password" for "Passowrd"
    And I press "Sign In"
    Then I should be on path "/index.php"
    And I should see "Thank you for signing in"
