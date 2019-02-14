# frozen_string_literal: true

require 'dotenv/load'
require 'telegram/bot'
require './db'

token = ENV['BOT_TOKEN']
force_trigger_commands = ['/help', '/start', '/reaccplsreacc']

def should_send
  rand(90).zero?
end

def user_to_logstr(user)
  return '' unless user

  "UNAME #{user.username}"
end

def msg_to_logstr(message)
  return '' unless message

  "MSGTXT \"#{message.text}\" FROM #{user_to_logstr(message.from)} MSGID #{message.message_id} DATE #{message.date} TYPE #{message.chat&.type} TITLE \"#{message.chat&.title}\" CHATID #{message.chat&.id}"
end

reply_keyboard = [[
  Telegram::Bot::Types::InlineKeyboardButton.new(text: '👍', callback_data: 'goodreacc'),
  Telegram::Bot::Types::InlineKeyboardButton.new(text: '👎', callback_data: 'badreacc')
]]
markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: reply_keyboard)

def log_incoming(message)
  puts "MSG: #{msg_to_logstr(message)}"
end

def log_reacc(trigger_msg, reacc_msg)
  unless reacc_msg['ok']
    puts "REACCFAIL: Reaction to #{message.chat&.id} failed to send"
    return
  end

  puts "REACC: \"#{trigger_msg.text}\" -> \"#{reacc_msg['result']['text']}\" REACCMSGID #{reacc_msg['result']['message_id']} ||| TRIGGER #{msg_to_logstr(trigger_msg)}"

  # Store reaction
  insert_reaction(trigger_msg, reacc_msg)
end

def handle_feedback(feedback_msg, bot, markup)
  puts "FEEDBACK: #{feedback_msg.data} FEEDBID #{feedback_msg.id} FROM #{user_to_logstr(feedback_msg.from)} ||| REACC #{msg_to_logstr(feedback_msg.message)} ||| TRIGGER #{msg_to_logstr(feedback_msg.message&.reply_to_message)}"

  # Store feedback
  reacc_message_id = feedback_msg.message&.message_id
  return if reacc_message_id.nil?

  case feedback_msg.data
  when 'goodreacc'
    increment_upvotes(reacc_message_id)
  when 'badreacc'
    increment_downvotes(reacc_message_id)
  end

  # TODO: Edit reacc with feedback score
  # bot.api.edit_message_text(chat_id)
  get_votes(reacc_message_id) do |row|
    reaction, upvotes, downvotes = row
    new_text = "#{reaction}\n_Verdict: #{(upvotes - downvotes).negative? ? '👎' : '👍'} #{upvotes - downvotes}_"
    bot.api.edit_message_text(chat_id: feedback_msg.message&.chat&.id,
                              message_id: reacc_message_id,
                              text: new_text,
                              parse_mode: 'Markdown',
                              reply_markup: markup)
  end
end

init_db

Telegram::Bot::Client.run(token) do |bot|
  puts 'Started'

  # Fetch bot data
  me = bot.api.getMe
  bot_username = me['result']['username']
  puts "Got bot UNAME #{bot_username} data #{me}"

  bot.listen do |message|
    case message
    when Telegram::Bot::Types::CallbackQuery
      handle_feedback(message, bot, markup)
      bot.api.answerCallbackQuery(callback_query_id: message.id,
                                  text: 'Thanks for the reacc reacc!')

    when Telegram::Bot::Types::Message
      log_incoming(message)

      commands = message.entities
                        .select { |e| e.type == 'bot_command' }
                        .map { |e| message.text[e.offset, e.length].split('@') }
                        .select { |c_comps| c_comps[1].nil? || c_comps[1] == bot_username }
                        .map(&:first)

      if (force_trigger_commands & commands).empty? == false || should_send
        reacction = File.readlines('reaccs.txt').sample
        reacction.strip!
        reacc_msg = bot.api.send_message(chat_id: message.chat.id,
                                         reply_to_message_id: message.message_id,
                                         text: reacction,
                                         parse_mode: 'Markdown',
                                         reply_markup: markup)
        log_reacc(message, reacc_msg)
      end
    end
  rescue StandardError => e
    puts 'Exception occurred'
    p e
  end
end
