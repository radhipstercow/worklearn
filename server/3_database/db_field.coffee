#######################################################
#
#Created by Markus on 26/10/2015.
#
#######################################################

#######################################################
@modify_field_unprotected = (collection, id, field, value) ->
	if not collection
		throw new Meteor.Error "Collection undefined."

	s = {}
	s[field] = value
	s['modified'] = new Date

	mod =
		$set:s

	n = collection.update(id, mod)

	msg = '[edit] Changed ' + field + ' of ' +
			collection._name + ':' + id + ' to ' +
			value.toString().substr(0, 50)

	console.log(msg)

	return n


#######################################################
@modify_field = (collection, id, field, value) ->
	if not collection
		throw new Meteor.Error "Collection undefined."

	deny_action_save('modify', collection, id, field)

	check value, Match.OneOf String, Number, Boolean

	res = modify_field_unprotected collection, id, field, value

	if typeof value == "string"
		predaid_add_text collection, id, field

	return res


#######################################################
@visible_fields = (collection, user_id, filter) ->
	owner = false

	if filter.owner_id
		if filter.owner_id == user_id
			owner = true

	roles = ['all']
	if owner
		roles.push 'owner'

	if user_id
		user = Meteor.users.findOne(user_id)

	if user
		roles.push user.roles ...
		roles.push 'anonymous'

	res = {}
	edit_fields = Permissions.find({}, {fields:{field:1}}).fetch()

	for field in edit_fields
		filter =
			role:
				$in: roles
			field: field.field
			collection_name: collection._name

		permissions = Permissions.find(filter)

		if permissions.count() == 0
			continue

		for permission in permissions.fetch()
			if action_permitted permission, 'read'
				res[field["field"]] = 1

	mod =
		fields: res

	return mod


