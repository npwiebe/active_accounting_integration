# ActiveInvoicing

**Note: This gem is still under active development**

ActiveInvoicing provides a Ruby interface for working with accounting platforms like QuickBooks and Xero. It handles OAuth2 authentication, API requests, and gives you ActiveModel-style objects to work with.

## Installation

Add to your Gemfile:

```ruby
gem 'active_invoicing'
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
ActiveInvoicing.configure do |config|
  config.quickbooks_client_id = 'your_client_id'
  config.quickbooks_client_secret = 'your_client_secret'
end
```

## QuickBooks Usage

### Authentication

First, you need to get the user to authorize your app with QuickBooks:

```ruby
redirect_uri = "http://localhost:3000/callback"
connection = ActiveInvoicing::Accounting::Connection.new_connection(
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
customer = ActiveInvoicing::Accounting::Quickbooks::Customer.create(
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
invoice = ActiveInvoicing::Accounting::Quickbooks::Invoice.create(
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

ActiveInvoicing provides a powerful mountable module that allows your ActiveRecord models to seamlessly integrate with accounting platforms. This feature enables bidirectional synchronization between your Rails models and accounting data.

### Setting Up Mountable Models

First, include the mountable concern in your ActiveRecord model:

```ruby
class User < ApplicationRecord
  include ActiveInvoicing::ActiveRecord::Mountable

  # Add columns to store external IDs
  # t.string :quickbooks_customer_id
end
```

### Mounting Accounting Models

Use the `mounts_accounting_model` method to connect your model to accounting entities:

```ruby
class User < ApplicationRecord
  include ActiveInvoicing::ActiveRecord::Mountable

  # Mount a QuickBooks customer
  mounts_accounting_model :quickbooks_customer,
    class_name: "ActiveInvoicing::Accounting::Quickbooks::Customer",
    external_id_column: :quickbooks_customer_id

end
```

### Connection Methods

Your model needs to provide connection methods that return authenticated accounting connections:

```ruby
class User < ApplicationRecord
  def quickbooks_customer_connection
    # Return an authenticated QuickBooks connection
    @quickbooks_connection ||= ActiveInvoicing::Accounting::Connection.new_connection(
      :quickbooks,
      access_token: self.quickbooks_access_token,
      refresh_token: self.quickbooks_refresh_token,
      realm_id: self.quickbooks_realm_id
    )
  end
end
```

### Accessing Accounting Models

Once mounted, you get automatic getter and setter methods:

```ruby
user = User.find(1)
user.quickbooks_customer_id = "123"

# Get the accounting model
customer = user.quickbooks_customer
puts customer.display_name # => "John Doe"

# Set the accounting model (updates the external ID)
user.quickbooks_customer = some_customer_object
user.quickbooks_customer_id # => "456"
```

### Synchronization

The mountable module provides powerful synchronization methods:

#### Sync To Accounting Model

Push data from your Rails model to the accounting platform:

```ruby
user = User.find(1)
user.name = "Updated Name"
user.email = "updated@example.com"
user.sync_to_quickbooks_customer # Uses default mapping
```

#### Sync From Accounting Model

Pull data from the accounting platform to your Rails model:

```ruby
user = User.find(1)

# Pull latest data from QuickBooks
user.sync_from_quickbooks_customer

# This will update user.name, user.email, etc. from the accounting data
```

#### Custom Mappers

For complex mappings, you can provide separate mappers for each direction or a single mapper for both:

**Option 1: Separate mappers (recommended for clarity)**

```ruby
class User < ApplicationRecord
  mounts_accounting_model :quickbooks_customer,
    class_name: "ActiveInvoicing::Accounting::Quickbooks::Customer",
    external_id_column: :quickbooks_customer_id,
    mapper_to: ->(accounting_model) do
      # Rails -> Accounting: Map from self (Rails model) to accounting model
      {
        display_name: "#{first_name} #{last_name}",
        primary_email_address: { address: email },
        company_name: business_name
      }
    end,
    mapper_from: ->(accounting_model) do
      # Accounting -> Rails: Map from accounting model to self (Rails model)
      {
        first_name: accounting_model.given_name,
        last_name: accounting_model.family_name,
        email: accounting_model.primary_email_address&.address
      }
    end
end
```

### Default Mappings

When no custom mapper is provided, the module automatically discovers and maps **all attributes** with matching names between your Rails model and the accounting model.

**For example:** If your Rails model has a `phone` attribute and the QuickBooks customer model also has a `phone` attribute, they will be automatically synchronized in both directions without any custom mapper code.

### Complete Example

```ruby
class User < ApplicationRecord
  include ActiveInvoicing::ActiveRecord::Mountable

  # Database columns
  # t.string :quickbooks_customer_id
  # t.string :name
  # t.string :email
  # t.string :first_name
  # t.string :last_name

  mounts_accounting_model :quickbooks_customer,
    class_name: "ActiveInvoicing::Accounting::Quickbooks::Customer",
    external_id_column: :quickbooks_customer_id

  def quickbooks_customer_connection
    ActiveInvoicing::Accounting::Connection.new_connection(
      :quickbooks,
      access_token: quickbooks_access_token,
      refresh_token: quickbooks_refresh_token,
      realm_id: quickbooks_realm_id
    )
  end

  # Usage examples:
  def create_or_update_in_quickbooks
    if quickbooks_customer_id.nil?
      # Create new customer in QuickBooks
      customer = ActiveInvoicing::Accounting::Quickbooks::Customer.create(
        display_name: name,
        primary_email_address: { address: email },
        connection: quickbooks_customer_connection
      )
      self.quickbooks_customer = customer
      save
    else
      # Update existing customer
      sync_to_quickbooks_customer
    end
  end

  def refresh_from_quickbooks
    sync_from_quickbooks_customer if quickbooks_customer_id.present?
  end
end
```

The mountable functionality keeps your Rails application and accounting data in sync, handling the API authentication, data mapping, and bidirectional synchronization automatically.

## Xero Usage

Xero support is still being built out :)

## Supported Providers

**QuickBooks** - Customers, Invoices, and Payments are fully supported. Is mountable. 

## License

MIT License

