class_name TestTool extends Node


# Tool for implementing tests and test cases. Use by calling TestTool.run().

static var _errors_for_current_test_case: Array[String]
static var _passed_count: int = 0
static var _failed_count: int = 0


class TestCase_base:
	var description: String


# NOTE: test_case_function accepts arg of TestCase and
# returns TestCaseResult.
static func run(test_name: String, test_case_list: Array, test_case_function: Callable):
	print("--- Start testing of %s ---" % test_name)

	for i in test_case_list.size():
		var test_case: TestCase_base = test_case_list[i]
		var test_case_description: String = test_case.description

#		Run the test case
		test_case_function.call(test_case)

		var passed: bool = TestTool._errors_for_current_test_case.is_empty()

# 		Print PASS/FAIL message
		var status_string: String
		if passed:
			status_string = "PASS"
		else:
			status_string = "FAIL"

		print("%s\t : %s - %s" % [status_string, test_name, test_case_description])

#		Print details about why this test case failed
		if !passed:
			for error in TestTool._errors_for_current_test_case:
				print("%s" % error)

			TestTool._errors_for_current_test_case.clear()
		
		if passed:
			TestTool._passed_count += 1
		else:
			TestTool._failed_count += 1

	print("--- Finished testing of %s ---" % test_name)


static func compare(actual, expected, description: String = ""):
	if actual != expected:
		var fail_message: String = "Compared values are not the same\n\tActual: %s\n\tExpected: %s." % [str(actual), str(expected)]
		if !description.is_empty():
			fail_message += " Description: \"%s\"" % description

		TestTool._errors_for_current_test_case.append(fail_message)


static func verify(condition: bool, message: String):
	if !condition:
		var fail_message: String = "Verify failed: %s" % [message]
		TestTool._errors_for_current_test_case.append(fail_message)


static func print_totals():
	print("Totals: %d passed, %d failed" % [TestTool._passed_count, TestTool._failed_count])
