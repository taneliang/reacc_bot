require 'dotenv/load'
require 'telegram/bot'

token = ENV['BOT_TOKEN']

def should_send
  rand(90).zero?
end

Telegram::Bot::Client.run(token) do |bot|
  puts 'Started'
  bot.listen do |message|
    p message
    if message.text == '/help' || message.text == '/start' || should_send
      reply = File.readlines('reaccs.txt').sample
      bot.api.send_message(chat_id: message.chat.id,
                           reply_to_message_id: message.message_id,
                           text: reply)
    end
  end
end
