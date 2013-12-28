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
end