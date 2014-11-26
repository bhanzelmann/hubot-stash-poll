# test framework
expect = require('chai').expect

# dependencies/helpers
Q = require('q')
helpers = require('../helpers')
testContext = require('../test_context')

# test target
bot = require('../../src/scripts/bot')


describe 'bot | commands | unping', ->
  context = {}

  beforeEach (done) ->
    testContext (testContext) ->
      context.robot = testContext.robot
      context.sandbox = testContext.sandbox
      context.user = testContext.user
      bot(context.robot)
      done()

  afterEach ->
    context.sandbox.restore()


  # =========================================================================
  #  INTERNAL TEST HELPERS
  # =========================================================================
  whenRemoving = (name, api_url) ->
    deferred = Q.defer()

    message = "stash-poll unping #{name} #{api_url}"
    helpers.onRobotReply context.robot, context.user, message, (replyData) ->
      replyData.referencedRepo =
        context.robot.brain.data['stash-poll']?[api_url]
      deferred.resolve(replyData)

    deferred.promise


  # =========================================================================
  #  LISTENER
  # =========================================================================
  describe 'listener', ->
    it 'should register', ->
      # given
      stub = context.robot.respond.withArgs(/stash-poll unping ([^\s]+) (.*)/i)

      # then
      expect(stub.calledOnce).to.equal true


    it 'should send an error message if repo is not found', ->
      # given
      expected = 'There was no repo with api url http://a.com/foo - maybe ' +
                 'you should add it?'

      # then
      whenRemoving('@foobar', 'http://a.com/foo').then ({envelope, strings}) ->
        expect(strings[0]).to.equal expected


    it 'should send an error message when room is not subscribing to repo', ->
      # given
      helpers.brainFor(context.robot)
        .repo('http://a.com/foo')

      expected = '#mocha is not subscribing to http://a.com/foo - maybe ' +
                 'you should add it?'

      # then
      whenRemoving('@foobar', 'http://a.com/foo').then ({envelope, strings}) ->
        expect(strings[0]).to.equal expected


    it 'should acknowledge removed ping', ->
      # given
      helpers.brainFor(context.robot)
        .repo('http://a.com/foo', ['#mocha'])

      expected =
        'Notifications for http://a.com/foo will no longer ping @foobar'

      # then
      whenRemoving('@foobar', 'http://a.com/foo').then ({envelope, strings}) ->
        expect(strings[0]).to.equal expected


    it 'should remove the name from the repo ping list', ->
      # given
      repo = helpers.brainFor(context.robot)
        .repo('http://a.com/foo', ['#mocha'], ['@foobar', '_test'])
        .repo()

      # then
      whenRemoving('_test', 'http://a.com/foo').then ({envelope, strings}) ->
        expect(repo.pings).to.eql ['@foobar']


