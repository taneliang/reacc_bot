require 'dotenv/load'
require 'telegram/bot'

token = ENV['BOT_TOKEN']

def should_send
  rand(90).zero?
end

def user_to_logstr(user)
  return "" unless user
  "UNAME #{user.username}"
end

def msg_to_logstr(message)
  return "" unless message
  "MSGTXT \"#{message.text}\" FROM #{user_to_logstr(message.from)} DATE #{message.date} TYPE #{message.chat&.type} TITLE \"#{message.chat&.title}\" CHATID #{message.chat&.id}"
end

def log_incoming(message)
  puts "MSG: #{msg_to_logstr(message)}"
end

def log_reacc(trigger_msg, reacc_msg)
  if !reacc_msg["ok"]
    puts "REACCFAIL: Reaction to #{message.chat&.id} failed to send"
    return
  end

  puts "REACC: \"#{trigger_msg.text}\" -> \"#{reacc_msg["result"]["text"]}\" REACCMSGID #{reacc_msg["result"]["message_id"]} ||| TRIGGER #{msg_to_logstr(trigger_msg)}"

  # TODO: Store reaction
end

def handle_feedback(feedback_msg)
  puts "FEEDBACK: #{feedback_msg.data} FEEDBID #{feedback_msg.id} ||| REACC #{msg_to_logstr(feedback_msg.message)} ||| TRIGGER #{msg_to_logstr(feedback_msg.message&.reply_to_message)}"
  # TODO: Store feedback
  # TODO: Edit reacc with feedback score
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
