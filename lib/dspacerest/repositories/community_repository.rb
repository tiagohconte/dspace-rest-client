module DSpaceRest
  module Repositories
    class CommunityRepository < AbstractRepository
      # Communities in DSpace are used for organization and hierarchy, and are containers that hold sub-Communities and Collections.

      # √ GET /communities - Returns array of all communities in DSpace.
      # √ GET /communities/top-communities - Returns array of all top communities in DSpace
      # √ GET /communities/{communityId} - Returns community
      # √ GET /communities/{communityId}/communities - Returns array of subcommunities of community.
      # √ POST /communities - Create new community at top level. You must post community.
      # √ POST /communities/{communityId}/communities - Create new subcommunity in community. You must post Community.
      # PUT /communities/{communityId} - Update community. You must put Community
      # DELETE /communities/{communityId} - Delete community.
      # DELETE /communities/{communityId}/communities/{communityId2} - Delete subcommunity in community.

      def get_community_by_id(id, params)
        query_string = build_query_string(params)
        response = rest_client["/communities/#{id}?#{query_string}"].get
        DSpaceRest::Community.new(JSON.parse(response))
      end

      def get_all_communities(params)
        query_string = build_query_string(params)
        response = rest_client["/communities?#{query_string}"].get
        communities = []
        JSON.parse(response).each do |comm|
          communities << DSpaceRest::Community.new(comm)
        end
        communities
      end

      def get_top_communities(params)
        query_string = build_query_string(params)
        response = rest_client["/communities/top-communities?#{query_string}"].get
        communities = []
        JSON.parse(response).each do |comm|
          communities << DSpaceRest::Community.new(comm)
        end
        communities
      end

      def get_subcommunities_of(community, params)
        query_string = build_query_string(params)
        response = rest_client["/communities/#{community.id}/communities?#{query_string}"].get
        communities = []
        JSON.parse(response).each do |comm|
          communities << DSpaceRest::Community.new(comm)
        end
        communities
      end

      def create_community(community)
        form = JSON.generate(community.to_h)
        response = rest_client["/communities"].post form
      end

      def create_subcommunity_of(community, subcommunity)
        form = JSON.generate(subcommunity.to_h)
        response = rest_client["/communities/#{community.id}/communities"].post form

        DSpaceRest::Community.new(JSON.parse(response))
      end

      private

      def expandable_properties
        ["parentCommunity","collections","subCommunities","logo","all"]
      end

      def query_parameters
        ["limit","offset"]
      end

    end
  end
end
