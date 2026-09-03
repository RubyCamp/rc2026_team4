class DetailsOfShiftsController < ApplicationController
def index
  @work_requests = WorkRequest
    .includes(:business, :required_skill, assignments: :staff_member)
    .order(:starts_at)

  if params[:keyword].present?
    keyword = "%#{params[:keyword]}%"

    @work_requests = @work_requests
      .joins(:business, :required_skill)
      .where(
        "work_requests.title ILIKE :keyword
         OR businesses.name ILIKE :keyword
         OR skills.name ILIKE :keyword",
        keyword: keyword
      )
  end
    if params[:shortage].present?
    case params[:shortage]
    when "yes"
      @work_requests = @work_requests.select do |work_request|
        work_request.staffing_shortage_count > 0
      end
    when "no"
      @work_requests = @work_requests.select do |work_request|
        work_request.staffing_shortage_count == 0
      end
    end
  end
end

  def show
    @work_request = WorkRequest
      .includes(:business, :required_skill, assignments: :staff_member)
      .find(params[:id])
      @staff_members = StaffMember
      .includes(:skills, :availabilities)
      .order(:name)
  end

  def edit
    @work_request = WorkRequest.find(params[:id])
  end

  def update
    @work_request = WorkRequest.update_details!(
      id: params[:id],
      attributes: work_request_params
    )

    redirect_to @work_request, notice: "勤務依頼の備考を更新しました。"
  rescue ActiveRecord::RecordInvalid => error
    raise unless error.record.is_a?(WorkRequest)

    @work_request = error.record
    render :edit, status: :unprocessable_content
  rescue ActiveRecord::RecordNotFound
    redirect_to work_requests_path, alert: "更新する勤務依頼が見つかりませんでした。"
  end

  private

  def work_request_params
    params.expect(work_request: [ :notes ])
  end
end
