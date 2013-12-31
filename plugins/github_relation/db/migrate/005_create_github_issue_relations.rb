class CreateGithubIssueRelations < ActiveRecord::Migration
  def change
    create_table :github_issue_relations do |t|
      t.references :issue_relation
      t.references :issue_from
      t.references :issue_to
    end
  end
end