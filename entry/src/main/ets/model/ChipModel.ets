export interface ChipModel {
  id: number
  name: string
  model: string
  manufacturer_id: number
  category_id: number
  architecture: string
  process_node: string
  release_date: string
  key_specs_json: string      // 卡片摘要 {"显存":"80GB","算力":"989 TFLOPS"}
  detail_specs_json: string   // 详情完整参数 [{"group":"计算性能","name":"FP16算力","value":"989","unit":"TFLOPS"}]
  description: string
  image_path: string
  search_keywords: string
  is_hot: number
  is_new: number
  is_deleted: number
  update_time: number
  db_version: number
}
