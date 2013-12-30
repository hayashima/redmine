module Github
  class Relation

    def initialize(login, password)
      @login = login
      @password = password
    end

    def client
      @client || Octokit::Client.new(login: @login, password: @password)
    end

    def issues(organization, project)
      all_list_from_github(organization, project) do |repo, option|
        client.list_issues(repo, option)
      end
    end

    def issue_comments(organization, project, number)
      all_list_from_github(organization, project) do |repo, option|
        client.issue_comments(repo, number, option)
      end
    end

    def issue(organization, project, number)
      target = "#{organization}/#{project}"
      client.issue(target, number)
    end

    def users(organization)
      client.organization_members(organization)
    rescue
      []
    end

    private
    def all_list_from_github(organization, project)
      repo = "#{organization}/#{project}"

      list_all = []
      begin
        page = (page || 0) + 1
        list = yield repo, {page: page, per_page: 100}
        list_all += list
      end
      list_all
    end
  end
end