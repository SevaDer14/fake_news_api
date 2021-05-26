class Api::StatisticsController < ApplicationController
  before_action :authenticate_editor

  def index
    @statistics = {}
    api_key = 'bearer sk_test_51IovvJL7WvJmM60HFPImrEIk25YfJ3ovv4YOLXN77R43J7ZmPth8fKKvi2qoneds5w50RAblSRPIlaIXo2PMFEhy00w7WvCun0'
    get_local_statistics
    begin
      response = RestClient.get('https://api.stripe.com/v1/subscriptions', headers: { Authorization: api_key })
      data = JSON.parse(response)
      stripe_data_extractor(data)
    rescue StandardError => e      
      stripe_error = JSON.parse(e.response)['error']['message']
      render json: { statistics: @statistics, stripe_error: stripe_error }, status: e.response.code  and return
    end
    render json: { statistics: @statistics }
  end

  private

  def authenticate_editor
    return if current_user.editor?

    render json: { error_message: 'You are not authorized to view this information' }, status: 403
  end

  def get_local_statistics
    @statistics[:articles] = {
      total: Article.where(backyard: false).count,
      published: Article.where(published: true, backyard: false).count,
      unpublished: Article.where(published: false, backyard: false).count
    }
    @statistics[:backyard_articles] = { total: Article.where(backyard: true).count }
    @statistics[:journalists] = { total: User.where(role: 5).count }
  end

  def stripe_data_extractor(data)
    amount_of_subscribers =
      { total: 0,
        yearly_subscription: 0,
        half_year_subscription: 0,
        monthly_subscription: 0 }

    total_income = {
      yearly_subscription: 0,
      half_year_subscription: 0,
      monthly_subscription: 0
    }

    data['data'].each do |subscription|
      amount_of_subscribers[:total] += 1
      id = subscription['items']['data'].first['price']['id']
      case id
      when 'yearly_subscription'
        amount_of_subscribers[:yearly_subscription] += 1
        total_income[:yearly_subscription] = amount_of_subscribers[:yearly_subscription] * 100
      when 'half_year_subscription'
        amount_of_subscribers[:half_year_subscription] += 1
        total_income[:half_year_subscription] = amount_of_subscribers[:half_year_subscription] * 110
      when 'monthly_subscription'
        amount_of_subscribers[:monthly_subscription] += 1
        total_income[:monthly_subscription] = amount_of_subscribers[:monthly_subscription] * 130
      end
    end
    @statistics[:subscribers] = amount_of_subscribers
    @statistics[:total_income] = total_income
  end
end
