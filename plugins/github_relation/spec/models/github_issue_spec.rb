require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'github_issue' do
  fixtures :trackers, :issue_statuses, :enumerations, :users

  let!(:project){Project.create(name: 'github_test', identifier: 'github_test')}

  let!(:github_users){
    %w{user assignee}.map do |user_name|
      user = Hashie::Mash.new
      user.login = "#{user_name}_login"
      user
    end
  }

  before do
    GithubUser.create_users(github_users)

    github_issues = 10.times.map do |index|
      issue = Hashie::Mash.new
      issue.number = index
      issue.title = "title#{index}"
      issue.body = "body#{index}"
      issue.created_at = Time.parse("2010/01/01")
      issue.updated_at = Time.parse("2011/01/01")
      issue.user = github_users[0]
      issue
    end
    github_issues[5].assignee = github_users[1]
    github_issues[6].user.login = "hoge"

    GithubIssue.create_issues(project, github_issues)
  end

  context "create_issues" do
    subject{GithubIssue.scoped.order(:issue_number)}
    its(:count){should == 10}
    it "GithubIssues" do
      subject.each_with_index do |github_issue, index|
        github_issue.issue_number.should == index
        github_issue.issue.subject.should == "title#{index}"
        github_issue.issue.description.should == "body#{index}"
        github_issue.issue.created_on.should == Time.parse("2010/01/01")
        github_issue.issue.updated_on.should == Time.parse("2011/01/01")
      end
    end
    it "GithubIssues User" do
      user = GithubUser.where(login: "user_login").first.user

      (0..4).each do |index|
        subject[index].issue.author.should == user
        subject[index].issue.assigned_to.should == nil
      end
      (7..9).each do |index|
        subject[index].issue.author.should == user
        subject[index].issue.assigned_to.should == nil
      end

      subject[5].issue.author.should == user
      subject[5].issue.assigned_to.should == GithubUser.where(login: "assignee_login").first.user
      subject[6].issue.author.should == User.first
      subject[6].issue.assigned_to.should == nil
    end
  end

  context "update_closed_issues" do
    before do
      issue = Hashie::Mash.new
      issue.number = 3
      issue.title = "title3"
      issue.body = "body3"
      issue.created_at = Time.parse("2010/01/01")
      issue.updated_at = Time.parse("2011/01/01")
      issue.closed_at = Time.parse("2012/01/01")
      issue.user = github_users[0]

      github_issue = GithubIssue.where(issue_number: 3).first
      github_issue.update_from_github(project, issue, :close)
    end

    subject{GithubIssue.scoped.order(:issue_number)}

    it "GithubIssues closed_on" do
      subject.each_with_index do |github_issue, index|
        unless index == 3
          github_issue.issue.closed_on.present?.should == false
          github_issue.issue.status.is_closed?.should == false
        end
      end
      subject[3].issue.closed_on.should == Time.parse("2012/01/01")
      subject[3].issue.status.is_closed?.should == true
    end

  end

  describe "issue_comments" do
    let!(:issue){GithubIssue.first}
    before do
      issue_comments = 10.times.map do |index|
        comment = Hashie::Mash.new
        comment.id = index
        comment.body = "body#{index} #{index + 1} #{index + 2}"
        comment
      end

      issue.set_issue_comment_from_github(issue_comments)
      issue.create_and_delete_relation_issues
    end

    subject{GithubIssueComment.scoped.order(:id)}

    context "create_from_github" do
      its(:count){should == 10}
      it "github_comment" do
        subject.each_with_index do |issue_comment, index|
          issue_comment.issue_comment_number.should == index.to_s
          issue_comment.github_issue.should == issue
          issue_comment.journal.notes.should == "body#{index} #{index + 1} #{index + 2}"
        end
      end

      it "github_relation" do
        issue_relations = IssueRelation.all
        issue_relations.count.should == 17

        issue_relations.each_with_index do |issue_comment, index|
          issue_comment.issue_comment_number.should == index.to_s
          issue_comment.github_issue.should == issue
          issue_comment.journal.notes.should == "body#{index} #{index + 1} #{index + 2}"
        end
      end
    end

    context "update_and_delete_from_github" do
      before do
        issue_comments = 8.times.map do |index|
          comment = Hashie::Mash.new
          comment.id = index
          comment.body = "body#{index + 1}"
          comment
        end

        issue.set_issue_comment_from_github(issue_comments)
      end

      its(:count){should == 8}
      it "journal" do
        Journal.scoped.count.should == 8
      end
      it "github_comment" do
        subject.each_with_index do |issue_comment, index|
          issue_comment.issue_comment_number.should == index.to_s
          issue_comment.github_issue.should == issue
          issue_comment.journal.notes.should == "body#{index + 1}"
        end
      end
    end
  end
end