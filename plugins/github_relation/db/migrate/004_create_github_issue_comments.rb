class CreateGithubIssueComments < ActiveRecord::Migration
  def change
    create_table :github_issue_comments do |t|
      t.column :issue_comment_number, :string
      t.references :github_issue
      t.references :journal
    end
  end
end