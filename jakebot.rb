require 'cinch'
require 'twitter'
require 'yaml'

affirmatives = [ "Got it!", "Word.", "For sure, yo.", "Fo shizzle." ]
welcomes = [ "What up.", "Yo!", "The funk has arrived." ]
greetings = [ "Hello", "What up", "Hi", "How you been", "How ya doin", "Howdy" ]
jakeisms = [ "So how has everyone's day been?", "beep boop", "RBE is the best. You guys are just jealous", "I could sure go for some Pi in me right now...", "miku es mai waifu", "I love Spanish! Quiero un mexicano que me jodas en el culo!", "hi im drum", "Destroyer 666 is actually great! You just don't understand.", "Metal is good", "The RBE lab is the best place on campus", "*sigh* I wish I was as cool as Pi.", "BOMBEROS!" ]

bot_dir = File.expand_path "~/.jakebot"
welcome_messages = {}
channels = ["#bottest"]
VERSION = '0.2.3.1'

keys = YAML.load(File.read("#{bot_dir}/keys"))

client = Twitter::REST::Client.new do |config|
  tw_keys = keys['twitter']

  config.consumer_key = tw_keys['consumer_key']
  config.consumer_secret = tw_keys['consumer_secret']
  config.access_token = tw_keys['access_token']
  config.access_token_secret = tw_keys['access_token_secret']
end

bot = Cinch::Bot.new do
  # Configure the bot

  configure do |c|
    c.server = "irc.phinugamma.org"
    c.channels = channels
    c.nick = "jakebot"
  end

  # Register handlers

  on :message, /^(hello|hi) jakebot/ do |m|
    m.reply "#{greetings.sample} #{m.user.nick}"
  end

  on :message, /^!tweet (.+)/ do |m, tw|
    tweet = client.update tw
    m.reply "#{affirmatives.sample} It's been tweeted at #{tweet.url}"
  end

  on :message, /^!welcome (.+)/ do |m, message|
    welcome_messages[m.user.nick] = message
    m.reply "#{affirmatives.sample}"

    # Save the messages
    IO.write("#{bot_dir}/welcome", YAML.dump(welcome_messages))
  end

  on :message, /^(.+)$/ do |m, message|
    # Save the message or update stats w/e
  end

  on :join do |m|
    greeting = greetings.sample

    # Case of bot joining
    if m.user == bot.nick
      m.reply "HELLO EVERYONE! I AM JAKEBOT v#{VERSION}"
    else
      m.channel.op(m.user)
      if welcome_messages.key?(m.user.nick)
        m.reply welcome_messages[m.user.nick]
      else
        m.reply welcomes.sample
      end
    end
  end

  on :message, /^!topic ?add (.+)/ do |m, new_topic|
    current_topic = m.channel.topic
    if current_topic.empty? 
      m.channel.topic = new_topic
    else
      m.channel.topic = "#{current_topic} | #{new_topic}"
    end
  end

  on :message, /^!topic ?rem(ove)? (.+)/ do |m, garbage, top|
    # Remove an items from the topic
    
    reg = Regexp.new(top, true) # Case insensitive regexp
    current_topic = m.channel.topic
    topic_segments = current_topic.split(" | ")
    
    topic_segments.each do |t|
      if reg =~ t
        topic_segments.delete(t)
      end
    end
    
    new_topic = topic_segments.join(" | ")
    
    if new_topic.eql? current_topic
      # If the edited topic and new topic are the same, the
      # requested item to delete must not have been found
      m.reply "That's not in the topic" 
    else
      m.channel.topic = new_topic
    end
  end

  # Start timers

  Timer(10 * 60) { # Every 10 minutes
    if rand < 0.25 # 25% chance
      channels.each do |chan| Channel(chan).send(jakeisms.sample) end
    end
  }
end

# Create the storage directory if it doesn't exist
Dir.mkdir(bot_dir) unless File.exists?(bot_dir)

# Load the saved welcome messages, if they exist
if File.exists?("#{bot_dir}/welcome")
  welcome_messages = YAML.load_file("#{bot_dir}/welcome")
end

# Start the bot
bot.start
