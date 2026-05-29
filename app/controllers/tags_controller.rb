class TagsController < ApplicationController
  before_action :set_organization
  before_action :set_tag, only: [:edit, :update, :destroy]

  def index
    @tags = @organization.tags.order(:name)
  end

  def new
    @tag = @organization.tags.new
  end

  def create
    @tag = @organization.tags.new(tag_params)

    if @tag.save
      respond_to do |format|
        format.html { redirect_to organization_tags_path(@organization), notice: "Tag created successfully" }
        format.json { render json: { success: true, tag: @tag } }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, error: @tag.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @tag.update(tag_params)
      respond_to do |format|
        format.html { redirect_to organization_tags_path(@organization), notice: "Tag updated successfully" }
        format.json { render json: { success: true, tag: @tag } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, error: @tag.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to organization_tags_path(@organization), notice: "Tag deleted successfully" }
      format.json { render json: { success: true } }
    end
  end

  private

  def set_tag
    @tag = @organization.tags.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :color)
  end
end
