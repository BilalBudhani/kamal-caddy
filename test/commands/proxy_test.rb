require "test_helper"

class CommandsProxyTest < ActiveSupport::TestCase
  setup do
    @config = {
      service: "app", image: "dhh/app", registry: { "username" => "dhh", "password" => "secret" }, servers: [ "1.1.1.1" ], builder: { "arch" => "amd64" }
    }

    ENV["EXAMPLE_API_KEY"] = "456"
  end

  teardown do
    ENV.delete("EXAMPLE_API_KEY")
  end

  test "run" do
    assert_equal \
      "docker run --name kamal-proxy --network kamal --detach --restart unless-stopped --publish 80:80 --publish 443:443 --volume kamal-proxy-config:/home/kamal-proxy/.config/kamal-proxy --log-opt max-size=\"10m\" basecamp/kamal-proxy:#{Kamal::Configuration::PROXY_MINIMUM_VERSION}",
      new_command.run.join(" ")
  end

  test "run with ports configured" do
    assert_equal \
      "docker run --name kamal-proxy --network kamal --detach --restart unless-stopped --publish 80:80 --publish 443:443 --volume kamal-proxy-config:/home/kamal-proxy/.config/kamal-proxy --log-opt max-size=\"10m\" basecamp/kamal-proxy:#{Kamal::Configuration::PROXY_MINIMUM_VERSION}",
      new_command.run.join(" ")
  end

  test "run without configuration" do
    @config.delete(:proxy)

    assert_equal \
      "docker run --name kamal-proxy --network kamal --detach --restart unless-stopped --publish 80:80 --publish 443:443 --volume kamal-proxy-config:/home/kamal-proxy/.config/kamal-proxy --log-opt max-size=\"10m\" basecamp/kamal-proxy:#{Kamal::Configuration::PROXY_MINIMUM_VERSION}",
      new_command.run.join(" ")
  end

  test "run with logging config" do
    @config[:logging] = { "driver" => "local", "options" => { "max-size" => "100m", "max-file" => "3" } }

    assert_equal \
      "docker run --name kamal-proxy --network kamal --detach --restart unless-stopped --publish 80:80 --publish 443:443 --volume kamal-proxy-config:/home/kamal-proxy/.config/kamal-proxy --log-driver \"local\" --log-opt max-size=\"100m\" --log-opt max-file=\"3\" basecamp/kamal-proxy:#{Kamal::Configuration::PROXY_MINIMUM_VERSION}",
      new_command.run.join(" ")
  end

  test "proxy start" do
    assert_equal \
      "docker container start kamal-proxy",
      new_command.start.join(" ")
  end

  test "proxy stop" do
    assert_equal \
      "docker container stop kamal-proxy",
      new_command.stop.join(" ")
  end

  test "proxy info" do
    assert_equal \
      "docker ps --filter name=^kamal-proxy$",
      new_command.info.join(" ")
  end

  test "proxy logs" do
    assert_equal \
      "docker logs kamal-proxy --timestamps 2>&1",
      new_command.logs.join(" ")
  end

  test "proxy logs since 2h" do
    assert_equal \
      "docker logs kamal-proxy  --since 2h --timestamps 2>&1",
      new_command.logs(since: "2h").join(" ")
  end

  test "proxy logs last 10 lines" do
    assert_equal \
      "docker logs kamal-proxy  --tail 10 --timestamps 2>&1",
      new_command.logs(lines: 10).join(" ")
  end

  test "proxy logs with grep hello!" do
    assert_equal \
      "docker logs kamal-proxy --timestamps 2>&1 | grep 'hello!'",
      new_command.logs(grep: "hello!").join(" ")
  end

  test "proxy remove container" do
    assert_equal \
      "docker container prune --force --filter label=org.opencontainers.image.title=kamal-proxy",
      new_command.remove_container.join(" ")
  end

  test "proxy remove image" do
    assert_equal \
      "docker image prune --all --force --filter label=org.opencontainers.image.title=kamal-proxy",
      new_command.remove_image.join(" ")
  end

  test "proxy follow logs" do
    assert_equal \
      "ssh -t root@1.1.1.1 -p 22 'docker logs kamal-proxy --timestamps --tail 10 --follow 2>&1'",
      new_command.follow_logs(host: @config[:servers].first)
  end

  test "proxy follow logs with grep hello!" do
    assert_equal \
      "ssh -t root@1.1.1.1 -p 22 'docker logs kamal-proxy --timestamps --tail 10 --follow 2>&1 | grep \"hello!\"'",
      new_command.follow_logs(host: @config[:servers].first, grep: "hello!")
  end

  test "version" do
    assert_equal \
      "docker inspect kamal-proxy --format '{{.Config.Image}}' | cut -d: -f2",
      new_command.version.join(" ")
  end

  private
    def new_command
      Kamal::Commands::Proxy.new(Kamal::Configuration.new(@config, version: "123"))
    end
end