DashboardPage = require '../pages/dashboard/page'

describe 'Dashboard Page', ->
  page = null

  beforeAll ->
    page = new DashboardPage()
    page.visitPage()

  describe 'Layout', ->

    it 'Dashboard page has the breadcrumb Home / Dashboard', ->
      expect(page.breadcrumbs).toEqual ['Home', 'Dashboard']

    it 'Dashboard page has the title Welcome> To the DIA-Distributed project', ->
      expect(page.title).toEqual 'Welcome> To the DIA-Distributed project'
