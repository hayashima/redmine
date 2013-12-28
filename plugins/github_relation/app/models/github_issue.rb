class GithubIssue < ActiveRecord::Base
  attr_accessible :issue_number

  belongs_to :issue

  def self.create_issues(project, list_issues)
    list_issues.each do |issue_from_github|
      github_issue = GithubIssue.where(issue_number: issue_from_github.number).first_or_create()
      github_issue.update_from_github(project, issue_from_github)
      github_issue.save!
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
  end
end
