class Api::RatingsController < ApplicationController
  def create
    article = Article.find(params[:article_id])
    article.ratings.create(rating: params[:rating])
    render json: { message: 'You successfuly rated this article' }, status: 201
  end

  private

  def rating_params
    params.permit(:article_id, :rating)
  end
end
