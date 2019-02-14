require 'dotenv/load'
require 'telegram/bot'

token = ENV['BOT_TOKEN']

def should_send
  rand(90).zero?
end

def log_incoming(message)
  puts "MSG: \"#{message.text}\" ||| #{message.from&.username} #{message.date} #{message.chat&.type} \"#{message.chat&.title}\" #{message.chat&.id}"
end

def log_reacc(trigger_msg, reacc_msg)
  if !reacc_msg["ok"]
    puts "Reaction to #{message.chat&.id} failed to send"
    return
  end

  puts "REACC: \"#{trigger_msg.text}\" -> \"#{reacc_msg["result"]["text"]}\" ||| #{trigger_msg.from&.username} #{trigger_msg.date} #{trigger_msg.chat&.type} \"#{trigger_msg.chat&.title}\" #{trigger_msg.chat&.id} #{reacc_msg["result"]["message_id"]}"

  # TODO: Store reaction
end

def handle_feedback(feedback_msg)
  puts "FEEDBACK: To \"#{feedback_msg.message.text}\" #{feedback_msg.data} ID #{feedback_msg.id} OrigMsgID #{feedback_msg.message.message_id} ||| #{feedback_msg.message.from&.username} #{feedback_msg.message.date} #{feedback_msg.message.chat&.type} \"#{feedback_msg.message.chat&.title}\" #{feedback_msg.message.chat&.id}"
end

reply_keyboard = [[
  Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Good reacc', callback_data: 'goodreacc'),
  Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Bad reacc', callback_data: 'badreacc'),
]]
markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: reply_keyboard)

Telegram::Bot::Client.run(token) do |bot|
  puts 'Started'
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::CallbackQuery
      handle_feedback(message)
      bot.api.answerCallbackQuery(callback_query_id: message.id, 'text': "Thanks for the reacc reacc!")

    when Telegram::Bot::Types::Message
      log_incoming(message)
      if message.text == '/help' || message.text == '/start' || should_send
        reacction = File.readlines('reaccs.txt').sample
        reacction.strip!
        reacc_msg = bot.api.send_message(chat_id: message.chat.id,
                                         reply_to_message_id: message.message_id,
                                         text: reacction,
                                         reply_markup: markup)
        log_reacc(message, reacc_msg)
      end
    end
  end
end
