class GithubIssueRelation < ActiveRecord::Base
  attr_accessible :issue_from_id, :issue_to_id

  belongs_to :issue_from, :class_name => 'GithubIssue', :foreign_key => 'issue_from_id'
  belongs_to :issue_to, :class_name => 'GithubIssue', :foreign_key => 'issue_to_id'
  belongs_to :issue_relation

  after_create :create_issue_relation
  after_destroy :destroy_issue_relation

  private
  def create_issue_relation
    issue_relation = IssueRelation.new
    issue_relation.issue_from = issue_from.issue
    issue_relation.issue_to = issue_to.issue
    issue_relation.save!
    self.issue_relation = issue_relation
    self.save!
  end

  def destroy_issue_relation
    self.issue_relation.destroy
  end
end
