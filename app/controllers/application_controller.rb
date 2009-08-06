# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  around_filter :neo_tx

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'efb0b5600e8e340eb3584dabecb14b88'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  def linker(params)
    
    @origin = Neo4j.load(params[:origin_id]) if params[:origin_id]
    @target = Neo4j.load(params[:target_id]) if params[:target_id]

    # construct predicate type
    @rel_string = params[:origin_type] + "_to_" + params[:target_type]

    case @rel_string
      when "person_to_person"
        rel = @origin.person_to_person.new(@target)        
      when "person_to_organisation"
        rel = @origin.person_to_org.new(@target)        
      when "person_to_location"
        rel = @origin.person_to_loc.new(@target)        
      when "person_to_event"
        rel = @origin.person_to_event.new(@target)        
      when "person_to_reference"
        rel = @origin.person_to_ref.new(@target)        

      when "organisation_to_person"
        rel = @target.person_to_org.new(@origin)   # note that the direction of the relationship necessitates inversion of the creation order
      when "organisation_to_organisation"
        rel = @origin.org_to_org.new(@target)        
      when "organisation_to_location"
        rel = @origin.org_to_loc.new(@target)        
      when "organisation_to_event"
        rel = @origin.org_to_event.new(@target)        
      when "organisation_to_reference"
        rel = @origin.org_to_ref.new(@target)        

      when "location_to_person"
        rel = @target.person_to_loc.new(@origin)        
      when "location_to_organisation"
        rel = @target.org_to_loc.new(@origin)        
      when "location_to_location"
        rel = @origin.loc_to_loc.new(@target)        
      when "location_to_event"
        rel = @target.org_to_event.new(@origin)        
      when "location_to_reference"
        rel = @origin.org_to_ref.new(@target)        

      when "event_to_person"
        rel = @target.person_to_event.new(@origin)        
      when "event_to_organisation"
        rel = @target.org_to_event.new(@origin)        
      when "event_to_location"
        rel = @origin.event_to_loc.new(@target)        
      when "event_to_event"
        rel = @origin.event_to_event.new(@target)        
      when "event_to_reference"
        rel = @origin.event_to_ref.new(@target)        

       when "reference_to_person"
        rel = @target.person_to_ref.new(@origin)        
      when "reference_to_organisation"
        rel = @target.org_to_ref.new(@origin)        
      when "reference_to_location"
        rel = @target.loc_to_ref.new(@origin)        
      when "reference_to_event"
        rel = @target.event_to_ref.new(@origin)        

      
      when "reference_to_reference"
        rel = @origin.ref_to_ref.new(@target)        

    end

    # relationship name (used for further domain reasoning eg direct family, wider family, etc)
    rel.name = params[:link_category]

    # date ranges for past/ongoing plus timeline visualisation
    rel.start_date = params[:start_date]
    rel.end_date = params[:end_date]

    # notes about the relationship
    unless params[:notes] == "<insert notes about this link here>" then
      rel.notes = params[:notes]
    end

  end
  
  def unlinker(params)
    @origin = Neo4j.load(params[:id]) if params[:id]
    @target = Neo4j.load(params[:target_id]) if params[:target_id]
    relationship = Neo4j.load_relationship(params[:neo_relationship_id])
    if (relationship) then
      relationship.delete
    end
  end
  
  private

  def neo_tx
    Neo4j::Transaction.new
    yield
    Neo4j::Transaction.finish
  end
end
