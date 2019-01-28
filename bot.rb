require 'dotenv/load'
require 'telegram/bot'

token = ENV['BOT_TOKEN']

replies = [
  'LOL',
  'lol',
  'Lol',
  'oh lol',
  'lmao',
  'Lmao',
  'Rip',
  'rip',
  'Wew',
  'wew',
  'Kek',
  'kek',
  'Hahaha',
  'HAHA',
  'Hahahaha',
  'wtf',
  'Wtf',
  'Nice',
  'Sick',
  'issit',
  'Chey',
  'wat',
  'gg',
  'H A C K E R M A N',
  'You should out elitist them!',
  'xD',
  'sgtm',
  'lgtm',
  'How about no',
  'erm',
  '^',
  'cri',
  'RT',
  'ded',
  'damn',
  '可以吃的吗？',
  '?',
  'ah',
  '/goodbot',
  '/badbot',
  '/bigthonk',
  '/wasted',
  '...'
]

def should_send
  rand(70).zero?
end

Telegram::Bot::Client.run(token) do |bot|
  puts 'Started'
  bot.listen do |message|
    p message
    if message.text == '/help' || message.text == '/start' || should_send
      bot.api.send_message(chat_id: message.chat.id,
                           reply_to_message_id: message.message_id,
                           text: replies.sample)
    end
  end
end
