
SUBSYSTEM_DEF(department)
	name = "Departments"
	init_stage = INITSTAGE_EARLY
	flags = SS_NO_FIRE

	var/list/datum/company/companies = list()

/datum/controller/subsystem/department/Initialize(timeofday)

	for (var/company_type in subtypesof(/datum/company))
		var/datum/company/company = new company_type()
		var/list/departments = list()
		for (var/department_type in company.departments)
			departments += new department_type()
		company.departments = departments
		companies += company

	// Allocate jobs lookup table
	GLOB.exp_jobsmap = list(
		EXP_TYPE_CREW = 	get_all_jobs(),
		EXP_TYPE_COMMAND = SSdepartment.get_jobs_by_dept_id(DEPT_NAME_COMMAND),
		EXP_TYPE_ENGINEERING = SSdepartment.get_jobs_by_dept_id(DEPT_NAME_ENGINEERING),
		EXP_TYPE_MEDICAL = 	SSdepartment.get_jobs_by_dept_id(DEPT_NAME_MEDICAL),
		EXP_TYPE_SCIENCE = 	SSdepartment.get_jobs_by_dept_id(DEPT_NAME_SCIENCE),
		EXP_TYPE_SUPPLY = 	SSdepartment.get_jobs_by_dept_id(DEPT_NAME_CARGO),
		EXP_TYPE_SECURITY = SSdepartment.get_jobs_by_dept_id(DEPT_NAME_SECURITY),
		EXP_TYPE_SILICON = 	SSdepartment.get_jobs_by_dept_id(DEPT_NAME_SILICON)
	)

	return SS_INIT_SUCCESS

/datum/company
	/// Name of the company
	var/name = ""

	/// The display order, lower means it is displayed first
	var/display_order = 0

	/// The display colour of the company
	var/colour = ""

	/// Primary bank account of the company
	var/datum/bank_account/account = new /datum/bank_account

	/// List of jobs available for this company, at the top level
	/// (not in any department).
	var/list/available_jobs

	/// List of departments associated with the company, for companies that
	/// have multiple departments such as Nanotrasen.
	/// This list may be empty, in which case the entire accounts and
	/// employees list are directly in the company instead.
	var/list/datum/company_department/departments

	/// List of budget allocations that we have with this company, these let
	/// us automatically give money to other accounts.
	var/list/datum/budget_allocation/budget_allocations = list()

	/// List of employees who are in the company but are not part of any department
	/// This is not a list of everyone who is employed with the company, as it
	/// excludes those who are employed under a department.
	var/list/datum/registered_employee/employees = list()

/datum/company_department
	/// Name of the department in the company
	var/name = ""
	/// The display order, lower means it is displayed first
	var/display_order = 0
	/// The display colour of the department, a pale form of the company
	var/colour = "#000000"
	/// Account of this department
	var/datum/bank_account/account = new /datum/bank_account()
	/// List of available jobs in the department
	var/list/available_jobs
	/// List of employees in the department
	var/list/datum/registered_employee/employees = list()

/datum/registered_employee
	/// The employees bank account
	var/datum/bank_account/account
	/// Boolean value that records if this employee records has been removed
	/// from the system. Removed employees become read-only.
	var/removed = FALSE
	/// How much this employee gets paid each pay-cycle.
	var/paycheck = 0
	/// History associated with edits to the employee
	var/list/datum/registered_employee_history/history = list()

/datum/registered_employee/New(datum/bank_account/account)
	. = ..()
	src.account = account

/datum/registered_employee_history
	/// Which account is responsible for authoring this change
	var/datum/bank_account/author
	/// Records the account that we now pay into
	var/datum/bank_account/new_account
	/// Records the new deleted flag state
	var/new_removed = FALSE
	/// Records the new paycheck value
	var/new_paycheck

/datum/registered_employee_history/New(datum/bank_account/author, datum/bank_account/new_account, new_removed, new_paycheck)
	src.author = author
	src.new_account = new_account
	src.new_removed = new_removed
	src.new_paycheck = new_paycheck

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

/datum/company_department/default
	name = "Default"
	colour = "#ffffff"

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
	available_jobs = list(
		/datum/job/captain
	)
	display_order = COMPANY_DISPLAY_ORDER_NANOTRASEN

/datum/company_department/command
	name = "Management"
	colour = "#2f5ea5"
	display_order = 0
	available_jobs = list(
		/datum/job/head_of_personnel,
		/datum/job/lawyer,
	)

/datum/company_department/science
	name = "Science"
	colour = "#934a99"
	display_order = 1
	available_jobs = list(
		/datum/job/research_director,
		/datum/job/scientist,
		/datum/job/roboticist,
		/datum/job/exploration_crew,
	)

// ---------------------------------------------------------------------
//                                SERVICE
// ---------------------------------------------------------------------
/datum/company/independent
	name = "Independent"
	colour = "#3d6714"
	display_order = COMPANY_DISPLAY_ORDER_INDEPENDENT

// ---------------------------------------------------------------------
//                               SUPPLY (CARGO)
// ---------------------------------------------------------------------
/datum/company/cargo
	name = "Watabe Shipping"
	colour = "#83381b"
	display_order = COMPANY_DISPLAY_ORDER_CARGO
	available_jobs = list(
		/datum/job/quartermaster,
		/datum/job/cargo_technician,
		/datum/job/shaft_miner,
	)

// ---------------------------------------------------------------------
//                            ENGINEERING
// ---------------------------------------------------------------------
/datum/company/engineering
	name = "Lager-Fein Electric"
	colour = "#ff8929"
	display_order = COMPANY_DISPLAY_ORDER_ENGINEERING
	available_jobs = list(
		/datum/job/chief_engineer,
		/datum/job/station_engineer,
		/datum/job/atmospheric_technician,
	)

// ---------------------------------------------------------------------
//                               MEDICAL
// ---------------------------------------------------------------------
/datum/company/medical
	name = "AuriHealth Public Limited Company"
	colour = "#4da5e4"
	display_order = COMPANY_DISPLAY_ORDER_MEDICAL
	available_jobs = list(
		/datum/job/chief_medical_officer,
		/datum/job/medical_doctor,
		/datum/job/chemist,
		/datum/job/surgeon,
		/datum/job/geneticist,
		/datum/job/paramedic,
	)

// ---------------------------------------------------------------------
//                               SECURITY
// ---------------------------------------------------------------------
/datum/company/security
	name = "Garrison Private Security"
	colour = "#ae1e1e"
	display_order = COMPANY_DISPLAY_ORDER_SECURITY
	available_jobs = list(
		/datum/job/head_of_security,
		/datum/job/warden,
		/datum/job/security_officer,
		/datum/job/deputy,
		/datum/job/brig_physician,
	)
