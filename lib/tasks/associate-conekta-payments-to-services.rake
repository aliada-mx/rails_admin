# encoding: UTF-8
namespace :db do
  desc "Associate conekta payments to services"
  task :associate_conekta_payments_to_services => :environment do
    CONEKTA_API_KEY = Rails.application.secrets.conekta_secret_key.html_safe

    def get_charges(n:6000)
      all_charges = []
      final_params = {limit: '20'}
      puts "Querying conekta API for #{n} charges and params #{final_params}"

      (0..n).step(20).each do |i|
        response = Curl.get("https://api.conekta.io/charges",{:offset => i, status: 'paid'}.merge(final_params)) do|http|
          http.username = CONEKTA_API_KEY
          http.password = ''
          http.headers['Accept'] = 'application/vnd.conekta-v0.3.0+json'
        end

        charges = JSON.parse(response.body_str)
        all_charges.push(*charges)
      end
      if all_charges.size == 0
        raise 'Not payments found'
      end
      puts "Found #{all_charges.size} charges"
      all_charges
    end

    ActiveRecord::Base.transaction do
      charges = get_charges()

      payments_created = []
      charges.each do |charge|
        if charge['status'] == 'paid' && charge['description'].include?( 'Servicio' ) && charge['reference_id'].present?
          service = Service.find charge['reference_id']
          user = service.user

          unless service.payments.conekta_payments.any?
            payment = Payment.create_from_conekta_charge(charge, user, user.default_payment_provider, service)
            payments_created.push(payment)
          end
        end
      end
      puts "payments_created #{payments_created.count}"
    end
  end
end
