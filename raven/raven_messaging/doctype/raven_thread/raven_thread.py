# Copyright (c) 2024, The Commit Company (Algocode Technologies Pvt. Ltd.) and contributors
# For license information, please see license.txt

# import frappe
from frappe.model.document import Document


class RavenThread(Document):
	# begin: auto-generated types
	# This code is auto-generated. Do not modify anything in this block.

	from typing import TYPE_CHECKING

	if TYPE_CHECKING:
		from frappe.types import DF
		from raven.raven_messaging.doctype.raven_thread_message.raven_thread_message import RavenThreadMessage
		from raven.raven_messaging.doctype.raven_thread_participant.raven_thread_participant import RavenThreadParticipant

		channel_id: DF.Link
		messages: DF.Table[RavenThreadMessage]
		participants: DF.Table[RavenThreadParticipant]
		thread_message_id: DF.Link
	# end: auto-generated types

	pass
