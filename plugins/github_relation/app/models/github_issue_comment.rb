class GithubIssueComment < ActiveRecord::Base
  attr_accessible :issue_comment_number

  belongs_to :github_issue
  belongs_to :journal

  def update_from_github(issue_comment)
    new_journal = self.journal || github_issue.issue.init_journal(User.current)
    new_journal.notes = issue_comment.body
    new_journal.save!
    self.journal = new_journal
  end

  def relation_issues
    match_data = journal.notes.match /#(\d*)/

    issue_ids = []
    while match_data.present?
      issue_ids << match_data[1].to_i
      match_data = match_data.post_match.match /#(\d*)/
    end

    issue_ids
  end
end
