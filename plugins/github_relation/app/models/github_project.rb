class GithubProject < ActiveRecord::Base
  attr_accessible :organization, :project_name

  validates :organization, presence: true
  validates :project_name, presence: true

  belongs_to :project

  def get_from_github(login, password)
    github_relation = Github::Relation.new(login, password)

    GithubUser.create_users(github_relation.users(self.organization))

    list_issues = github_relation.issues(self.organization, self.project_name)
    updated_github_issues = GithubIssue.create_issues(self.project, list_issues)
    updated_issues = GithubIssue.where(issue_number: updated_github_issues.map{|issue| issue.number})

    github_issue_number = list_issues.map{|issue_from_github| issue_from_github.number}
    closed_issues = GithubIssue.where(issue_id: self.project.issues.open.map{|issue| issue.id}).
        where( GithubIssue.arel_table[:issue_number].not_in(github_issue_number))

    closed_issues.each do |issue|
      github_issue = github_relation.issue(self.organization, self.project_name, issue.issue_number)
      issue.update_from_github(self.project, github_issue, true)
    end

    (updated_issues + closed_issues).each do |issue|
      issue_comments = github_relation.issue_comments(self.organization, self.project_name, issue.issue_number)
      issue.set_issue_comment_from_github issue_comments
      issue.create_and_delete_relation_issues
    end
  end
end
