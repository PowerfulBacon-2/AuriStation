
SUBSYSTEM_DEF(department)
	name = "Departments"
	init_stage = INITSTAGE_EARLY
	flags = SS_NO_FIRE

	/// full list of department datums.
	var/list/department_datums
	/// assoc list of department datums by its department name(dept_id). The list may not have full departments of ingame.
	var/list/department_assoc


	/// department datums in a 'crew manifest' priority order. Only used for crew manifest window.
	var/list/sorted_department_for_manifest
	/// department datums in a 'job pref' priority order in character selection.
	var/list/sorted_department_for_latejoin

/datum/controller/subsystem/department/Initialize(timeofday)
	department_datums = list()
	department_assoc = list()

	for(var/datum/department_group/each_dept as anything in subtypesof(/datum/department_group))
		each_dept = new each_dept()

		department_datums += each_dept
		if(each_dept.dept_id)
			department_assoc[each_dept.dept_id] = each_dept

	var/datum/department_group/dummy_datum
	dummy_datum = dummy_datum // be gone compile warning
	sorted_department_for_manifest = list()
	sorted_department_for_latejoin = list()
	init_and_sort_department(sorted_department_for_manifest, NAMEOF(dummy_datum, manifest_category_order))
	init_and_sort_department(sorted_department_for_latejoin, NAMEOF(dummy_datum, pref_category_order))

	// I don't like this here, but this globallist can't take proper values on its declaration.
	GLOB.exp_jobsmap = list(
		EXP_TYPE_CREW = 	get_all_jobs(),
		EXP_TYPE_COMMAND = SSdepartment.get_jobs_by_dept_id(DEPT_NAME_COMMAND),
		EXP_TYPE_ENGINEERING = SSdepartment.get_jobs_by_dept_id(DEPT_NAME_ENGINEERING),
		EXP_TYPE_MEDICAL = 	SSdepartment.get_jobs_by_dept_id(DEPT_NAME_MEDICAL),
		EXP_TYPE_SCIENCE = 	SSdepartment.get_jobs_by_dept_id(DEPT_NAME_SCIENCE),
		EXP_TYPE_SUPPLY = 	SSdepartment.get_jobs_by_dept_id(DEPT_NAME_CARGO),
		EXP_TYPE_SECURITY = SSdepartment.get_jobs_by_dept_id(DEPT_NAME_SECURITY),
		EXP_TYPE_SERVICE = SSdepartment.get_jobs_by_dept_id(DEPT_NAME_SERVICE),
		EXP_TYPE_SILICON = 	SSdepartment.get_jobs_by_dept_id(DEPT_NAME_SILICON)
	)

	return SS_INIT_SUCCESS

/// Puts department datums into a list in a desired sort priority. Only called once in subsystem Initialize.
/// * list_instance<list>: takes a list instance, to initialize and sort departments into this list
/// * priority_varname<string/NAMEOF>: a hacky one since sorting code does the same thing.
/datum/controller/subsystem/department/proc/init_and_sort_department(list/list_instance, priority_varname)
	if(isnull(list_instance))
		CRASH("'list_instance' does not exist: target_var [priority_varname]")
	if(!islist(list_instance))
		CRASH("'list_instance' is not a list: target_var [priority_varname]")
	if(!priority_varname || !length(priority_varname))
		CRASH("something's wrong to init department: target_var [priority_varname]")

	var/list/_department_datums_to_sort = department_datums.Copy()
	var/sanity_check = 1000
	while(length(_department_datums_to_sort) && sanity_check--)
		if(!sanity_check)
			CRASH("the proc reached 0 sanity check - something's causing the infinite loop.")

		var/datum/department_group/current
		for(var/datum/department_group/each_dept in _department_datums_to_sort)
			if(!each_dept.vars[priority_varname])
				_department_datums_to_sort -= each_dept
				continue
			if(!current)
				current = each_dept
				continue
			if(each_dept.vars[priority_varname] < current.vars[priority_varname])
				current = each_dept
				continue
		list_instance += current
		_department_datums_to_sort -= current

/// WARNING: This always returns as a list.
/// If your bitflag only gets a single department, it will return as a list.
/datum/controller/subsystem/department/proc/get_department_by_bitflag(bitflag)
	var/return_result = list()
	. = return_result

	for(var/datum/department_group/each_dept in department_datums)
		if(each_dept.dept_bitflag & bitflag)
			. += each_dept

	return return_result

/datum/controller/subsystem/department/proc/get_department_by_dept_id(id)
	. = department_assoc[id]
	if(!.)
		CRASH("[id] isn't an existing department id.")
	return department_assoc[id]

/datum/controller/subsystem/department/proc/get_jobs_by_dept_id(id_or_list)
	if(!id_or_list)
		stack_trace("proc has no id value")
		return list()

	if(istext(id_or_list))
		var/datum/department_group/dept = department_assoc[id_or_list]
		return dept.jobs

	if(!islist(id_or_list))
		id_or_list = list(id_or_list)
	else if(islist(id_or_list?[1]))
		CRASH("You did something wrong. Check if you did like 'list(list())'")

	var/list/jobs_to_return = list()
	for(var/each in id_or_list)
		var/datum/department_group/dept = department_assoc[each]
		if(!dept)
			message_admins("is not exist: [each]")
			continue
		if(!length(dept.jobs))
			continue
		jobs_to_return |= dept.jobs

	return jobs_to_return

/datum/company
	/// Name of the company
	var/name = ""

	/// The display colour of the company
	var/colour = ""

	/// Primary bank account of the company
	var/datum/bank_account/account

	/// List of departments associated with the company, for companies that
	/// have multiple departments such as Nanotrasen.
	/// If this list is not defined, then a default department will be created
	/// that will be ignored on UIs
	var/list/datum/company_department/departments

	/// List of budget allocations that we have with this company, these let
	/// us automatically give money to other accounts.
	var/list/datum/budget_allocation/budget_allocations

	/// List of employees who are in the company but are not part of any department
	/// This is not a list of everyone who is employed with the company, as it
	/// excludes those who are employed under a department.
	var/list/datum/registered_employee/employees

/datum/company_department
	/// Name of the department in the company
	var/name = ""
	/// The display colour of the department, a pale form of the company
	var/colour = "#000000"
	/// Account of this department
	var/datum/bank_account/account
	/// List of employees in the department
	var/list/datum/registered_employee/employees

/datum/registered_employee
	/// The employees bank account
	var/datum/bank_account/account
	/// Boolean value that records if this employee records has been removed
	/// from the system. Removed employees become read-only.
	var/removed = FALSE
	/// How much this employee gets paid each pay-cycle.
	var/paycheck = 0
	/// History associated with edits to the employee
	var/list/datum/registered_employee_history/history

/datum/registered_employee_history
	/// Which account is responsible for authoring this change
	var/datum/bank_account/author
	/// Records the account that we now pay into
	var/datum/bank_account/new_account
	/// Records the new deleted flag state
	var/new_removed = FALSE
	/// Records the new paycheck value
	var/new_paycheck

/datum/budget_allocation
	/// Name of the allocation, used to identify what this payment actually
	/// is.
	var/allocation_name = ""

	/// The author that created this budget allocation, or null if there is
	/// no data associated with it.
	var/datum/bank_account/author = null

	/// The account that the budget is allocated to
	var/datum/bank_account/target_account

	/// The amount that is paid out into the target account
	var/amount = 0

	/// History of all edits that have happened to this budget
	var/list/datum/budget_allocation_history/history

/datum/budget_allocation_history
	/// Which account is responsible for authoring this change
	var/datum/bank_account/author
	/// New name of the budget
	var/new_name
	/// New amount allocated to this budget
	var/new_amount
	/// The new account that we are paying into
	var/datum/bank_account/new_account

// ---------------------------------------------------------------------
//                                COMMAND
// ---------------------------------------------------------------------
/datum/company/command
	name = "Nanotrasen"
	colour = "#142c95"
	departments = list(
		/datum/company_department/command,
		/datum/company_department/science,
	)

/datum/company_department/command
	name = "Management"
	colour = "#2f5ea5"

/datum/company_department/science
	name = "Science"
	colour = "#934a99"

// ---------------------------------------------------------------------
//                                SERVICE
// ---------------------------------------------------------------------
/datum/company/independant
	name = "Independant"
	colour = "#3d6714"

// ---------------------------------------------------------------------
//                               SUPPLY (CARGO)
// ---------------------------------------------------------------------
/datum/company/cargo
	name = "Watabe Shipping"
	colour = "#83381b"

// ---------------------------------------------------------------------
//                            ENGINEERING
// ---------------------------------------------------------------------
/datum/company/engineering
	name = "Lager-Fein Electric"
	colour = "#ff8929"

// ---------------------------------------------------------------------
//                               MEDICAL
// ---------------------------------------------------------------------
/datum/company/medical
	name = "AuriHealth Public Limited Company"
	colour = "#4da5e4"

// ---------------------------------------------------------------------
//                               SECURITY
// ---------------------------------------------------------------------
/datum/company/security
	name = "Garrison Private Security"
	colour = "#ae1e1e"
