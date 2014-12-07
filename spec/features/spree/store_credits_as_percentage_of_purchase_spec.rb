require 'spec_helper'

RSpec.describe 'Promotion for Store Credits as Percentage', type: :feature, inaccessible: true do
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:payment_method) { create(:credit_card_payment_method) }
  let!(:zone) { create(:zone) }

  context "#new user" do
    let(:address) { create(:address, :state => Spree::State.first) }
    let(:promotion) { create(:promotion_for_store_credits_as_percentage, path: 'orders', created_at: 2.days.ago) }

    before do
      promotion
      shipping_method.calculator.set_preference(:amount, 10)
    end

    it "should give me a store credit when I purchase an order", :js => true do
      email = 'paul@gmail.com'
      setup_new_user_and_sign_up(email)
      new_user = Spree.user_class.where(email: email).first
      expect(new_user.store_credits.count).to eq(0)
      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in_credit_card

      click_button "Save and Continue"

      click_button Spree.t(:place_order)
      
      expect(page).to have_content("Your order has been processed successfully")
      expect(Spree::Order.count).to eq(1) 
      expect(new_user.store_credits.count).to eq(1)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $3.00")
    end

    it "should not give me a store credit for unfinished purchases", :js => true do
      email = 'paul@gmail.com'
      setup_new_user_and_sign_up(email)
      new_user = Spree.user_class.where(email: email).first
      expect(new_user.store_credits.count).to eq(0)
      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in_credit_card

      click_button "Save and Continue"

      expect(Spree::Order.count).to eq(1) 
      expect(new_user.store_credits.count).to eq(0)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to_not have_content("Current store credit: $3.00")
    end

    it "should no give me a store credit when I view a past order", :js => true do
      email = 'paul@gmail.com'
      setup_new_user_and_sign_up(email)
      new_user = Spree.user_class.where(email: email).first
      expect(new_user.store_credits.count).to eq(0)
      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in_credit_card

      click_button "Save and Continue"

      click_button Spree.t(:place_order)
      
      expect(page).to have_content("Your order has been processed successfully")
      order_path = spree.order_path(Spree::Order.last)
      expect(current_path).to eql(spree.order_path(Spree::Order.last))
      expect(Spree::Order.count).to eq(1) 
      expect(new_user.store_credits.count).to eq(1)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $3.00")

      visit order_path

      visit spree.account_path
      expect(page).to have_content("Current store credit: $3.00")      
    end 

    it "should accumulate my store credits", :js => true do
      email = 'paul@gmail.com'
      setup_new_user_and_sign_up(email)
      new_user = Spree.user_class.where(email: email).first
      expect(new_user.store_credits.count).to eq(0)
      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      fill_in_credit_card

      click_button "Save and Continue"

      click_button Spree.t(:place_order)
      
      expect(page).to have_content("Your order has been processed successfully")
      order_path = spree.order_path(Spree::Order.last)
      expect(current_path).to eql(spree.order_path(Spree::Order.last))
      expect(Spree::Order.count).to eq(1) 
      expect(new_user.store_credits.count).to eq(1)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $3.00")

      bag = create(:product, name: "RoR Bag", price: 59.99)
      visit spree.root_path
      click_link bag.name
      expect(page).to have_content(Spree.t(:add_to_cart))
      click_button "add-to-cart-button"

      expect(new_user.store_credits.count).to eq(1)
      click_button "Checkout"

      fill_in_address
      click_button "Save and Continue"
      click_button "Save and Continue"
      expect(page).to have_content("Use an existing card on file")
      fill_in "order_store_credit_amount", :with => "0"

      click_button "Save and Continue"

      click_button Spree.t(:place_order)
      
      expect(Spree::Order.count).to eq(2) 
      expect(new_user.store_credits.count).to eq(2)

      # store credits should be consumed
      visit spree.account_path
      expect(page).to have_content("Current store credit: $12.00")      
    end    

    after(:each) { reset_spree_preferences }
  end
end