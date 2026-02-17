# ActiveAccountingIntegration

**Note: This gem is still under active development**

ActiveAccountingIntegration provides a Ruby interface for working with accounting platforms like QuickBooks and Xero. It handles OAuth2 authentication, API requests, and gives you ActiveModel-style objects to work with.

## Installation

Add to your Gemfile:

```ruby
gem 'active_accounting_integration'
```

Then run:

```bash
bundle install
```

## Setup

### Configuration

Set these environment variables:

```bash
QUICKBOOKS_CLIENT_ID=your_client_id
QUICKBOOKS_CLIENT_SECRET=your_client_secret
```

Or configure directly in your code:

```ruby
ActiveAccountingIntegration.configure do |config|
  config.quickbooks_client_id = 'your_client_id'
  config.quickbooks_client_secret = 'your_client_secret'
end
```

## QuickBooks Usage

### Authentication

First, you need to get the user to authorize your app with QuickBooks:

```ruby
redirect_uri = "http://localhost:3000/callback"
connection = ActiveAccountingIntegration::Connection.new_connection(
  :quickbooks,
  redirect_uri
)

# Send the user to this URL
auth_url = connection.authorize_url
```

After the user authorizes, QuickBooks redirects back to your callback URL. Parse it:

```ruby
connection.parse_token_url(callback_url)
```

Now you have an authenticated connection. Save the tokens if you need them later:

```ruby
access_token = connection.access_token
refresh_token = connection.refresh_token
realm_id = connection.realm_id
```

The connection will automatically refresh expired tokens when making requests.

### Working with Customers

Fetch a single customer:

```ruby
customer = connection.fetch_customer_by_id("123")

puts customer.display_name
puts customer.company_name
puts customer.primary_email_address.address
puts customer.balance
```

Fetch all customers:

```ruby
customers = connection.fetch_all_customers

customers.each do |customer|
  puts "#{customer.display_name}: $#{customer.balance}"
end
```

Create a customer:

```ruby
customer = ActiveAccountingIntegration::Quickbooks::Customer.create(
  display_name: "Acme Corp",
  company_name: "Acme Corporation",
  primary_email_address: { address: "billing@acme.com" },
  billing_address: {
    line1: "123 Main St",
    city: "San Francisco",
    country_sub_division_code: "CA",
    postal_code: "94102"
  },
  connection: connection
)
```

Update a customer:

```ruby
customer = connection.fetch_customer_by_id("123")
customer.company_name = "New Company Name"
customer.save
```

### Working with Invoices

Fetch an invoice:

```ruby
invoice = connection.fetch_invoice_by_id("456")

puts invoice.doc_number
puts invoice.total
puts invoice.balance
puts invoice.due_date
```

Fetch all invoices:

```ruby
invoices = connection.fetch_all_invoices

invoices.each do |invoice|
  puts "Invoice ##{invoice.doc_number}: $#{invoice.total}"
end
```

Create an invoice:

```ruby
invoice = ActiveAccountingIntegration::Quickbooks::Invoice.create(
  customer_ref: { value: "123" },
  line_items: [
    {
      amount: 100.0,
      detail_type: "SalesItemLineDetail",
      sales_item_line_detail: {
        item_ref: { value: "1" }
      }
    }
  ],
  connection: connection
)
```

### Working with Payments

Fetch a payment:

```ruby
payment = connection.fetch_payment_by_id("789")

puts payment.total
puts payment.txn_date
puts payment.payment_ref_number
```

Fetch all payments:

```ruby
payments = connection.fetch_all_payments

payments.each do |payment|
  puts "Payment: $#{payment.total} on #{payment.txn_date}"
end
```

## ActiveRecord Integration

The Mountable concern lets your ActiveRecord models sync bidirectionally with accounting platforms. You define explicit mappers for each direction, and the concern handles fetching, caching, creating, and updating.

### Setup

Include the concern and mount an accounting model. `mapper_to` and `mapper_from` are required... you must explicitly define how your Rails attributes map to and from the accounting model's attributes.

```ruby
class User < ApplicationRecord
  include ActiveAccountingIntegration::ActiveRecord::Mountable

  # Database columns:
  # t.string :quickbooks_customer_id
  # t.string :first_name
  # t.string :last_name
  # t.string :email

  mounts_accounting_model :quickbooks_customer,
    class_name: "ActiveAccountingIntegration::Quickbooks::Customer",
    external_id_column: :quickbooks_customer_id,
    mapper_to: ->(accounting_model) {
      # Rails -> Accounting (self is the Rails model)
      {
        display_name: "#{first_name} #{last_name}",
        given_name: first_name,
        family_name: last_name,
        primary_email_address: { address: email },
      }
    },
    mapper_from: ->(accounting_model) {
      # Accounting -> Rails
      {
        first_name: accounting_model.given_name,
        last_name: accounting_model.family_name,
        email: accounting_model.primary_email_address&.address,
      }
    }
end
```

### Connections

You have two options for providing authenticated connections:

**Option 1: Global connection resolver (recommended)**

Set a resolver once in your initializer. It receives the ActiveRecord instance and the mount name, so it can look up the right credentials for any integration:

```ruby
ActiveAccountingIntegration.configure do |config|
  config.connection_resolver = ->(record, mount_name) {
    token = record.organization.oauth_tokens.find_by(provider: mount_name)
    # Build and return the appropriate connection
  }
end
```

**Option 2: Per-mount connection method**

Pass `connection_method:` to use a specific method on the model:

```ruby
mounts_accounting_model :quickbooks_customer,
  class_name: "ActiveAccountingIntegration::Quickbooks::Customer",
  external_id_column: :quickbooks_customer_id,
  connection_method: :qb_connection,
  mapper_to: ->(accounting_model) { ... },
  mapper_from: ->(accounting_model) { ... }

def qb_connection
  # Return an authenticated connection
end
```

If both are configured, `connection_method` takes precedence over the global resolver.

### Generated Methods

Mounting generates four methods on your model:

#### Getter (cached)

```ruby
user = User.find(1)
customer = user.quickbooks_customer          # Fetches from API, then caches
customer = user.quickbooks_customer          # Returns cached result (no API call)
customer = user.quickbooks_customer(reload: true)  # Forces re-fetch
```

#### Setter

```ruby
user.quickbooks_customer = some_customer  # Sets quickbooks_customer_id and caches
user.quickbooks_customer = nil            # Clears cache (keeps existing ID)
```

#### sync_to (with create-on-sync)

Pushes data from your Rails model to the accounting platform. If the record doesn't exist in the accounting platform yet (no external ID), it creates one automatically:

```ruby
user = User.find(1)

# If quickbooks_customer_id is nil, creates a new QB customer
# If quickbooks_customer_id is set, updates the existing one
user.sync_to_quickbooks_customer
```

#### sync_from

Pulls data from the accounting platform into your Rails model:

```ruby
user = User.find(1)
user.sync_from_quickbooks_customer
# user.first_name, user.last_name, user.email are now updated from QB
```

### Complete Example

```ruby
class User < ApplicationRecord
  include ActiveAccountingIntegration::ActiveRecord::Mountable

  mounts_accounting_model :quickbooks_customer,
    class_name: "ActiveAccountingIntegration::Quickbooks::Customer",
    external_id_column: :quickbooks_customer_id,
    mapper_to: ->(accounting_model) {
      {
        display_name: "#{first_name} #{last_name}",
        given_name: first_name,
        family_name: last_name,
        primary_email_address: { address: email },
      }
    },
    mapper_from: ->(accounting_model) {
      {
        first_name: accounting_model.given_name,
        last_name: accounting_model.family_name,
        email: accounting_model.primary_email_address&.address,
      }
    }

  # sync_to handles both create and update:
  def push_to_quickbooks
    sync_to_quickbooks_customer
  end

  def pull_from_quickbooks
    sync_from_quickbooks_customer if quickbooks_customer_id.present?
  end
end
```

## Xero Usage

Xero support is still being built out :)

## Supported Providers

**QuickBooks** - Customers, Invoices, and Payments are fully supported. Is mountable. 

## License

MIT License

