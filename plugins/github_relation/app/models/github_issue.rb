class GithubIssue < ActiveRecord::Base
  attr_accessible :issue_number

  has_many :github_issue_comments
  has_many :relation_to, :class_name => 'GithubIssueRelation', :foreign_key => 'issue_from_id'
  has_many :relation_to_issues, :through => :relation_to, :source => 'issue_to'

  belongs_to :issue

  def self.create_issues(project, list_issues)
    list_issues.select do |issue_from_github|
      github_issue = GithubIssue.where(issue_number: issue_from_github.number).first_or_create()
      github_issue.update_from_github(project, issue_from_github)
    end
  end

  def update_from_github(project, issue_from_github, status = :open)
    self.build_issue if issue.nil?
    return if issue.updated_on.present? && issue.updated_on > issue_from_github.updated_at

    issue.subject = issue_from_github.title
    issue.description = issue_from_github.body
    issue.project = project
    issue.tracker = Tracker.first
    issue.author = GithubUser.user_by_github_login(issue_from_github.user, User.first)
    if issue_from_github.assignee.present?
      issue.assigned_to = GithubUser.user_by_github_login(issue_from_github.assignee)
    end
    issue.created_on = issue_from_github.created_at
    issue.updated_on = issue_from_github.updated_at
    case status
      when :open
        issue.closed_on = nil
        issue.status = IssueStatus.where(is_closed: false).first
      when :close
        issue.closed_on = issue_from_github.closed_at
        issue.status = IssueStatus.where(is_closed: true).first
      else
    end

    Issue.skip_callback(:save, :before, :force_updated_on_change)
    Issue.skip_callback(:save, :before, :update_closed_on)
    issue.save!
    Issue.set_callback(:save, :before, :force_updated_on_change)
    Issue.set_callback(:save, :before, :update_closed_on)
    self.save!
    true
  end

  def set_issue_comment_from_github(issue_comments)
    issue_comments.each do |issue_comment_from_github|
      issue_comment = github_issue_comments.where(issue_comment_number: issue_comment_from_github.id.to_s).first_or_create
      issue_comment.github_issue = self
      issue_comment.update_from_github(issue_comment_from_github)
      issue_comment.save!
    end
  end

  def create_and_delete_relation_issues
    relation_issues.reject{|issue| relation_to_issues.any? {|relation| relation == issue}}.each do |issue|
      relation_to.create issue_to_id: issue.id
    end

    relation_to_issues.reject{|issue| relation_issues.any? {|relation| relation == issue}}.each do |issue|
      relation_to.where(issue_to_id: issue.id).each do |to_issue|
        to_issue.destroy
      end
    end
  end

  private
  def relation_issues
    issue_numbers = github_issue_comments.inject([]) do |numbers, github_issue|
      numbers + github_issue.relation_issues
    end
    GithubIssue.where(issue_number: issue_numbers.uniq)
  end

end
