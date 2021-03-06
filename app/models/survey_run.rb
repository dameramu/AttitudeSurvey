class SurveyRun < ActiveRecord::Base

  belongs_to :survey
  has_many :survey_responses, dependent: :destroy

  def self.active_survey_run
    find_by(active: true)
  end

  # return the % of the time this card was assigned to this category
  def proportion_card_assigned_to_category(card, category)
    card_count = survey.cards.length
    response_count = survey_responses.length
    
    # get the number of responses which assigned this card to this category
    card_to_cat_count = 
      survey_responses
      .joins(:card_placements)
      .where(card_placements: 
             {card_id: card.id, sensitivity_category_id: category.id}).length
    
    card_to_cat_count.to_f / response_count.to_f
  end

  # return number of times card shared with recipient
  def proportion_card_assigned_to_recipient(card, recipient)
    #response_count = survey_responses.length
    response_count = 0
    response_count = survey_responses.length - 
      survey_responses
      .joins(:sharing_prefs)
      .where(sharing_prefs:
             {recipient_id: recipient.id, card_id: card.id, share: nil}).length    
    
    share_count = 
      survey_responses
      .joins(:sharing_prefs)
      .where(sharing_prefs:
             {recipient_id: recipient.id, card_id: card.id, share: true}).length

    ((share_count.to_f / response_count.to_f) * 100).to_i
  end

  # get the proportions of sensitivity given a card-recipient assignment
  def sensitivities_assigned_to_recipient(card, recipient)
    share_count = 
      survey_responses
      .joins(:sharing_prefs)
      .where(sharing_prefs:
             {recipient_id: recipient.id, card_id: card.id, share: true}).length

    sensitivity_counts = { total: share_count }
    self.survey.sensitivity_categories.each do |sc| 
      sensitivity_counts[sc.title] =
        ((survey_responses
        .joins(:sharing_prefs, :card_placements)
        .where(sharing_prefs:
               {recipient_id: recipient.id, card_id: card.id, share: true},
               card_placements:
               {card_id: card.id, 
                 sensitivity_category_id: sc.id}).length.to_f / share_count.to_f)*100).round(2)
    end
    sensitivity_counts
  end

end

