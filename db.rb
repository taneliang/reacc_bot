# frozen_string_literal: true

require 'sqlite3'

def init_db
  with_db do |db|
    db.transaction
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS Reaccs(
      id INTEGER PRIMARY KEY,
      trigger TEXT NOT NULL,
      reaction TEXT NOT NULL,
      trigger_msg_author TEXT NOT NULL,
      chat_title TEXT,
      chat_type TEXT NOT NULL,
      chat_id TEXT NOT NULL,
      reacc_message_id TEXT NOT NULL,
      reacc_message_date INTEGER NOT NULL,
      upvotes INT NOT NULL DEFAULT 0,
      downvotes INT NOT NULL DEFAULT 0
      )
    SQL
    db.commit
  end
end

def insert_reaction(trigger_msg, reacc_msg)
  with_db do |db|
    db.execute 'INSERT INTO Reaccs(trigger, reaction, trigger_msg_author, chat_title, chat_type, chat_id, reacc_message_id, reacc_message_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', trigger_msg.text, reacc_msg['result']['text'], trigger_msg.from&.username, trigger_msg.chat&.title, trigger_msg.chat&.type, trigger_msg.chat&.id, reacc_msg['result']['message_id'], reacc_msg['result']['date']
  end
end

def increment_upvotes(reacc_message_id)
  with_db do |db|
    db.execute 'UPDATE Reaccs SET upvotes = upvotes + 1 WHERE reacc_message_id = ?', reacc_message_id
  end
end

def increment_downvotes(reacc_message_id)
  with_db do |db|
    db.execute 'UPDATE Reaccs SET downvotes = downvotes + 1 WHERE reacc_message_id = ?', reacc_message_id
  end
end

def get_votes(reacc_message_id)
  with_db do |db|
    db.execute 'SELECT reaction, upvotes, downvotes FROM Reaccs WHERE reacc_message_id = ?', reacc_message_id do |row|
      yield row
    end
  end
end

def with_db
  db = SQLite3::Database.open 'reacc.db'
  yield db
rescue SQLite3::Exception => e
  puts 'DB exception occurred'
  puts e
ensure
  db&.close
end
