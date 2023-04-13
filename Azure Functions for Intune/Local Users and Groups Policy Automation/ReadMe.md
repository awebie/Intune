# Local Users and Groups Automation

Just some policy automation I'm working on.
With how Azure AD groups are processed sometimes you need to specify a User SID rather than a group SID.
Obviously you don't want your helpdesk to edit your configuration policies so this is a means of providing them with a group to add people to and this policy will enumerate the relevant groups in policy for you.
Might blog about it but I'm not really happy with how this doesn't scale, although this is a limitation of local groups rather than the automation. Too many sids in a local group will cause performance issues.
In the JSON replace the local groups with whatever local groups you need to edit. It should work with custom groups as well although this hasn't been tested