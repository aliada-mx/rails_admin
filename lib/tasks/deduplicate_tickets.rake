namespace :db do
  desc "Deduplicate tickets"
  task :deduplicate_tickets => :environment do
	  services = {}  
    users = {}
    recurrences = {}

    Ticket.order(:id).all.each do |ticket|
      ticket_hash = " #{ ticket.category }-#{ ticket.relevant_object_type }-#{ ticket.relevant_object_id }"

      if ticket.relevant_object_type == 'Service'
        services[ticket_hash] = ticket.id
      end

      if ticket.relevant_object_type == 'User'
        users[ticket_hash] = ticket.id
      end

      if ticket.relevant_object_type == 'Recurrence'
        recurrences[ticket_hash] = ticket.id
      end
    end

    ids_to_keep = []
    ids_to_keep += services.map { |ticket_hash,id| id }
    ids_to_keep += users.map { |ticket_hash,id| id }
    ids_to_keep += recurrences.map { |ticket_hash,id| id }

    Ticket.where('id not in (?)', ids_to_keep).destroy_all
  end
end
